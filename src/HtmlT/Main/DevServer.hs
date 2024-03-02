module HtmlT.Main.DevServer where

import Control.Concurrent
import Control.Concurrent.Async
import Control.Exception
import Control.Monad
import Data.Binary qualified as Binary
import Data.ByteString as BS
import Data.ByteString.Lazy qualified as BSL
import Data.Function
import Data.IORef
import Data.List qualified as List
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Typeable
import Foreign.Store
import GHC.Generics
import GHC.IO.Exception
import Network.HTTP.Types as H
import Network.Wai as WAI
import Network.Wai.Application.Static
import Network.Wai.Handler.Warp as Warp
import Network.Wai.Handler.WebSockets
import Network.WebSockets
import System.Environment
import System.IO

import "this" HtmlT.Base
import "this" HtmlT.RJS
import "this" HtmlT.Protocol


data DevServerConfig a = DevServerConfig
  { aquire_resource :: IO a
  -- ^ Usualy runs once just after ghci session is loaded,
  -- e.g. establish connection to database etc
  , release_resource :: a -> IO ()
  -- ^ Runs before the ghci session is unloaded
  , reload_app :: IORef ConnectionState -> a -> IO ApplicationSpec
  -- ^ Given resource of type 'a', initialize instances of client and
  -- server applications. Runs each time ghci session reloads
  , html_template :: BSL.ByteString -> BSL.ByteString
  -- ^ Template for index.html, receives the current URL origin
  -- (protocol + host)
  , docroots :: [FilePath]
  -- ^ List of directories to use with wai-static middleware, could be
  -- empty, usually be used like docroots = ["./public"]
  } deriving Generic

data ApplicationSpec = ApplicationSpec
  { client_app :: StartFlags -> RJS ()
  , server_app :: Application
  , connection_lost :: ConnectionInfo -> IO ()
  -- ^ Will be executed after a connection closes
  } deriving Generic

defaultDevServerConfig :: (StartFlags -> RJS ()) -> DevServerConfig ()
defaultDevServerConfig clientApp = DevServerConfig
  { aquire_resource = pure ()
  , release_resource = const (pure ())
  , reload_app = \_ _ -> pure $ ApplicationSpec clientApp defaultFallbackApp (const (pure ()))
  , html_template = defaultHtmlTemplate
  , docroots = []
  }

runDebug :: Typeable resource => Warp.Settings -> DevServerConfig resource -> IO ()
runDebug settings cfg = do
  -- Using a random constant as the key for Foreign.Store
  let storeId = 183
  hSetBuffering stderr LineBuffering
  lookupStore storeId >>= \case
    Nothing -> do
      inst <- newInstance cfg
      writeStore (Store storeId) inst
      let
        useCurrentApp req resp = do
          RunningApp{devserver_config, server_app} <- readIORef inst.app_state_ref
          withStaticApp devserver_config.docroots server_app req resp
      forkIfRepl $ tryPort settings $
        devserverMiddleware inst useCurrentApp
    Just store -> do
      oldInst <- readStore store
      updateInstance cfg oldInst
      connState <- readIORef oldInst.conn_state_ref
      forM_ connState.connections \connInfo ->
        sendDataMessage connInfo.connection . Binary $ Binary.encode HotReload
  where
    tryPort :: Warp.Settings -> Application -> IO ()
    tryPort settings application = do
      hPutStrLn stderr $ "Running a Dev Server at http://localhost:" <>
        show (getPort settings) <> "/"
      result <- try $ runSettings settings application
      case result of
        Right () -> return ()
        Left (e::IOException)
          | ioe_type e == ResourceBusy -> do
            hPutStrLn stderr $ "Already in use, trying next port…"
            tryPort (setPort (getPort settings + 1) settings) application
          | otherwise -> throwIO e
    withStaticApp :: [FilePath] -> Middleware
    withStaticApp [] next = next
    withStaticApp (docroot:docroots) next =
      staticApp (defaultFileServerSettings docroot)
        {ss404Handler = Just (withStaticApp docroots next)}
    forkIfRepl action = do
      isRepl <- (== "<interactive>") <$> getProgName
      if isRepl then void (forkIO action) else action

runDebugPort :: Typeable resource => Warp.Port -> DevServerConfig resource -> IO ()
runDebugPort port cfg =
  runDebug (Warp.setPort port Warp.defaultSettings) cfg

runDebugDefault :: Warp.Port -> (StartFlags -> RJS ()) -> IO ()
runDebugDefault port clientApp = runDebug
  (Warp.setPort port Warp.defaultSettings)
  (defaultDevServerConfig clientApp)

devserverMiddleware :: DevServerInstance -> Middleware
devserverMiddleware opts next req resp =
  case pathInfo req of
    [] -> indexHtmlApp req resp
    ["index.html"] -> indexHtmlApp req resp
    ["dev-server.sock"] -> devserverApp req resp
    _ -> next req resp
  where
    devserverApp =
      websocketsOr defaultConnectionOptions (devserverWebsocket opts)
      defaultFallbackApp
    indexHtmlApp req resp = do
      let devSocket = devServerSocketUrl req
      RunningApp{devserver_config} <- readIORef opts.app_state_ref
      resp $ responseLBS status200
        [(hContentType, "text/html; charset=utf-8")] $
        devserver_config.html_template devSocket

devServerSocketUrl :: WAI.Request -> BSL.ByteString
devServerSocketUrl req =
  WAI.requestHeaders req
    & List.lookup "Host"
    & maybe "localhost" BSL.fromStrict
    & ((if WAI.isSecure req then "wss://" else "ws://") <>)
    & (<> "/dev-server.sock")

defaultHtmlTemplate :: BSL.ByteString -> BSL.ByteString
defaultHtmlTemplate devSocket =
  "<html>\n\
  \ <body>\n\
  \  <script>\n\
  \    " <> BSL.fromStrict indexBundleJs <> "\n\
  \    startDevClient(\"" <> devSocket <> "\");\n\
  \  </script>\n\
  \ </body>\n\
  \</html>\n"

defaultFallbackApp :: Application
defaultFallbackApp _ resp =
  resp $ responseLBS status404
    [(hContentType, "text/html; charset=utf-8")]
    "<html>\n\
    \ <body>\n\
    \   <h1>Not Found</h1>\n\
    \ </body>\n\
    \</html>\n"

type WorkerQueue = [WorkerJob]

type WorkerJob = (RunningApp, ClientMessage)

devserverWebsocket :: DevServerInstance -> ServerApp
devserverWebsocket opt p =
  let
    acceptConn = mdo
      connection <- acceptRequest p
      rjs_instance <- newRjsInstance
      command_chan <- newChan
      worker_queue <- newIORef []
      worker_feed <- newEmptyMVar
      worker_thread <- forkIO $ workerLoop connInfo
      let
        connInfo = ConnectionInfo
          { rjs_instance
          , connection
          , command_chan
          , connection_id
          , worker_thread
          , worker_queue
          , worker_feed }
      connection_id <- atomicModifyIORef' opt.conn_state_ref \s ->
        ( s
          { id_supply = succ s.id_supply
          , connections = Map.insert s.id_supply connInfo s.connections }
        , s.id_supply )
      return connInfo
    dropConn connInfo = do
      killThread connInfo.worker_thread
      modifyIORef' opt.conn_state_ref \s -> s
        {connections = Map.delete connInfo.connection_id s.connections}
      runningApp <- readIORef opt.app_state_ref
      runningApp.connection_lost connInfo
    receive c =
      try @ConnectionException (receiveData c)
    readingLoop connInfo = do
      runningApp <- readIORef opt.app_state_ref
      raceResult <- race (receive connInfo.connection) (readChan connInfo.command_chan)
      let
        mClientMsg = case raceResult of
          Left (Right (incomingBytes::ByteString)) ->
            Just $ BrowserMessage . Binary.decode . BSL.fromStrict $ incomingBytes
          Left (Left (_::ConnectionException)) ->
            Nothing
          Right jsAction ->
            Just $ DevServerMessage jsAction
      forM_ mClientMsg \clientMsg -> do
        let newJob = (runningApp, clientMsg)
        (nextJob, curJob) <- atomicModifyIORef' connInfo.worker_queue $ processQueue newJob
        feedEmpty <- isEmptyMVar connInfo.worker_feed
        case curJob of
          Just j | feedEmpty, canSkipJob nextJob j -> do
            -- Abort whatever the worker is doing, TriggerAnimation
            -- means previous frame no longer relevant, the new frame
            -- will override its results
            throwTo connInfo.worker_thread DropAnimationFrame
          _ -> return ()
        putMVar connInfo.worker_feed nextJob
      readingLoop connInfo
    workerLoopInner connInfo = do
      (runningApp, clientMsg) <- takeMVar connInfo.worker_feed
      haskMessage <- handleClientMessage connInfo.rjs_instance
        (runningApp.client_app . assignConnectionId connInfo) clientMsg
      -- TODO: check if it's fine writing to connection in this
      -- thread, which can be frequently aborted by DropAnimationFrame
      sendDataMessage connInfo.connection . Binary $ Binary.encode haskMessage
    workerLoop connInfo = do
      workerLoopInner connInfo `catch` \(_::DropAnimationFrame) -> return ()
      workerLoop connInfo
    assignConnectionId :: ConnectionInfo -> StartFlags -> StartFlags
    assignConnectionId cinfo flags = flags
      { devserver_connection_id = Just (fromIntegral cinfo.connection_id.unConnectionId)
      }
    processQueue :: WorkerJob -> WorkerQueue -> (WorkerQueue, (WorkerJob, Maybe WorkerJob))
    processQueue newJob [] = ([newJob], (newJob, Nothing))
    processQueue newJob [curJob] = ([newJob], (newJob, Just curJob))
    processQueue newJob (j:js)
      | canSkipJob newJob j = processQueue newJob js
      | otherwise =
        let
          (js', curJobs) = processQueueNe j (j:js)
        in
          (newJob:js', curJobs)
    processQueueNe :: WorkerJob -> WorkerQueue -> (WorkerQueue, (WorkerJob, Maybe WorkerJob))
    processQueueNe nextJob [] = ([], (nextJob, Nothing)) -- unreachable
    processQueueNe nextJob [curJob] = ([], (nextJob, Just curJob))
    processQueueNe _nextJob (j:js) =
      let
        (js', curJobs) = processQueueNe j js
      in
        (j:js', curJobs)
    canSkipJob :: WorkerJob -> WorkerJob -> Bool
    canSkipJob (_, j1) (_, j2)
      | BrowserMessage (TriggerAnimationMsg _ c1) <- j1
      , BrowserMessage (TriggerAnimationMsg _ c2) <- j2 =
        c1 == c2
      | otherwise = False
  in
    bracket acceptConn dropConn \connInfo ->
      withPingThread connInfo.connection 30 (pure ()) $ readingLoop connInfo

newInstance :: Typeable resource => DevServerConfig resource -> IO DevServerInstance
newInstance cfg = do
  resource <- cfg.aquire_resource
  conn_state_ref <- newIORef $ ConnectionState Map.empty 0
  appSpec <- cfg.reload_app conn_state_ref resource
  app_state_ref <- newIORef RunningApp
    { resource
    , devserver_config = cfg
    , client_app = appSpec.client_app
    , server_app = appSpec.server_app
    , connection_lost = appSpec.connection_lost }
  return DevServerInstance {conn_state_ref, app_state_ref}

updateInstance
  :: Typeable resource
  => DevServerConfig resource
  -> DevServerInstance
  -> IO ()
updateInstance cfg inst = do
  let
    tryOldResource :: forall a. Typeable a => DevServerConfig a ->
      RunningApp -> Either (IO ()) a
    tryOldResource _ RunningApp {resource, devserver_config}
      | Just Refl <- eqResource @a resource = Right resource
      | otherwise = Left (devserver_config.release_resource resource)
    eqResource :: forall a b. (Typeable a, Typeable b) => b -> Maybe (a :~: b)
    eqResource _ = eqT @a @b
  oldApp <- readIORef inst.app_state_ref
  case tryOldResource cfg oldApp of
    Right oldResource -> do
      appSpec <- cfg.reload_app inst.conn_state_ref oldResource
      writeIORef inst.app_state_ref RunningApp
        { resource = oldResource
        , devserver_config = cfg
        , client_app = appSpec.client_app
        , server_app = appSpec.server_app
        , connection_lost = appSpec.connection_lost
        }
    Left releaseOld -> do
      releaseOld
      newResource <- cfg.aquire_resource
      appSpec <- cfg.reload_app inst.conn_state_ref newResource
      writeIORef inst.app_state_ref RunningApp
        { resource = newResource
        , devserver_config = cfg
        , client_app = appSpec.client_app
        , server_app = appSpec.server_app
        , connection_lost = appSpec.connection_lost
        }

data DevServerInstance = DevServerInstance
  { conn_state_ref :: IORef ConnectionState
  , app_state_ref :: IORef RunningApp
  } deriving Generic

data ConnectionState = ConnectionState
  { connections :: Map ConnectionId ConnectionInfo
  , id_supply :: ConnectionId
  } deriving Generic

data ConnectionInfo = ConnectionInfo
  { connection :: Connection
  , rjs_instance :: RjsInstance
  , command_chan :: Chan (RJS ())
  -- ^ Writing to the Chan sends a command to the browser to execute
  , connection_id :: ~ConnectionId
  , worker_thread :: ThreadId
  , worker_queue :: IORef [(RunningApp, ClientMessage)]
  , worker_feed :: MVar (RunningApp, ClientMessage)
  } deriving Generic

data RunningApp = forall a. Typeable a => RunningApp
  { resource :: a
  , devserver_config :: DevServerConfig a
  , client_app :: StartFlags -> RJS ()
  , server_app :: Application
  , connection_lost :: ConnectionInfo -> IO ()
  }

newtype ConnectionId = ConnectionId {unConnectionId :: Int}
  deriving newtype (Ord, Show, Eq, Num, Enum)

-- | Run @yarn run webpack --mode production@ and copy contents here
-- from @./dist-newstyle/index.bundle.js@
indexBundleJs :: ByteString
indexBundleJs = "(()=>{\"use strict\";var __webpack_modules__={268:(e,t,r)=>{r.d(t,{BE:()=>P,IM:()=>h,IX:()=>T,OZ:()=>I,Z_:()=>y,a0:()=>O,a2:()=>x,bc:()=>m,cS:()=>M,qZ:()=>D,wY:()=>A});var _=r(849);class n{encode(e){const t=d(this,e),r=new Uint8Array(t);return g(this,r,0,e),r}decode(e){const[t,r]=f(this,e,0);return t}}class a extends n{}class s extends n{}class i extends n{}class o extends n{}class l extends n{constructor(e){super(),this._element=e}}class c extends n{constructor(e){super(),this._description=e}}class p extends n{constructor(e){super(),this._alternatives=e}}class u extends n{constructor(e){super(),this._self=e}}class E extends n{constructor(e){super(),this._tuple=e}}function d(e,t){if(e instanceof a)return 1;if(e instanceof s)return 8;if(e instanceof o){const e=t;return 8+(new TextEncoder).encode(e).length}if(e instanceof i)return 8+t.length;if(e instanceof l){const r=8;return t.reduce(((t,r)=>t+d(e._element,r)),r)}if(e instanceof c){const r=t;return Object.keys(e._description).reduce(((t,_)=>t+d(e._description[_],r[_])),0)}if(e instanceof p){const r=t;return b(Object.keys(e._alternatives).length)+d(e._alternatives[r.tag],r)}if(e instanceof u)return d(e._self,t);if(e instanceof E){const r=t;return e._tuple.reduce(((e,t,_)=>e+d(t,r[_])),0)}return(0,_.R)(e)}function f(e,t,r){if(e instanceof a)return[t[r],r+1];if(e instanceof s)return[t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56),r+8];if(e instanceof o){const e=t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56),_=t.subarray(r+8,r+8+e);return[new TextDecoder(\"utf8\").decode(_),r+8+e]}if(e instanceof i){const e=t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56);return[t.subarray(r+8,r+8+e),r+8+e]}if(e instanceof l){const _=t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56),n=[];let a=r+8;for(let r=0;r<_;r++){const[r,_]=f(e._element,t,a);n.push(r),a=_}return[n,a]}if(e instanceof c){let _=r;return[Object.fromEntries(Object.entries(e._description).map((([e,r])=>{const[n,a]=f(r,t,_);return _=a,[e,n]}))),_]}if(e instanceof p){const _=b(Object.keys(e._alternatives).length),[n,a]=function(e,t,r){if(1!=e)throw new Error(\"Unimplemented\");return[t[r],r+1]}(_,t,r),[s,i]=f(e._alternatives[n],t,a);return s.tag=n,[s,i]}if(e instanceof u)return f(e._self,t,r);if(e instanceof E){let _=r;return[e._tuple.map((e=>{const[r,n]=f(e,t,_);return _=n,r})),_]}return(0,_.R)(e)}function g(e,t,r,n){if(e instanceof a)return t[r]=n,r+1;if(e instanceof s){const e=n;return t[r+7]=255&e,t[r+6]=e>>8&255,t[r+5]=e>>16&255,t[r+4]=e>>24&255,r+8}if(e instanceof o){const e=n,_=(new TextEncoder).encode(e),a=_.length;return t[r+7]=255&a,t[r+6]=a>>8&255,t[r+5]=a>>16&255,t[r+4]=a>>24&255,t.set(_,r+8),r+8+a}if(e instanceof i){const e=n,_=e.length;return t[r+7]=255&_,t[r+6]=_>>8&255,t[r+5]=_>>16&255,t[r+4]=_>>24&255,t.set(e,r+8),r+8+_}if(e instanceof l){const _=n,a=_.length;t[r+7]=255&a,t[r+6]=a>>8&255,t[r+5]=a>>16&255,t[r+4]=a>>24&255;let s=r+8;for(let r=0;r<a;r++)s=g(e._element,t,s,_[r]);return s}if(e instanceof c){const _=n;let a=r;for(const r in e._description)Object.prototype.hasOwnProperty.call(e._description,r)&&(a=g(e._description[r],t,a,_[r]));return a}if(e instanceof p){const _=n.tag,a=b(Object.keys(e._alternatives).length);return t[r]=_,g(e._alternatives[_],t,r+a,n)}if(e instanceof u)return g(e._self,t,r,n);if(e instanceof E){const _=n;let a=r;return e._tuple.forEach(((e,r)=>{a=g(e,t,a,_[r])})),a}return(0,_.R)(e)}function b(e){return Math.ceil(Math.log2(e)/8)}const M=new a,x=new s,y=new o,D=new i;function T(e){return new l(e)}function h(e){return new c(e)}function O(e){return new p(e)}function m(...e){return new E(e)}function P(e){const t=new u(void 0),r=e(t);return t._self=r,r}var I;function A(e){return O({[I.Nothing]:h({}),[I.Just]:h({0:e})})}!function(e){e[e.Nothing=0]=\"Nothing\",e[e.Just=1]=\"Just\"}(I||(I={}))},849:(e,t,r)=>{function _(e){throw new Error(\"absurd: unreachable code\")}r.d(t,{O:()=>n,R:()=>_});class n{constructor(){this.counter=0,this.map=new Map}push(e){const t=this.counter++;return this.map.set(t,e),t}set(e,t){this.map.set(e,t)}get(e){return this.map.get(e)}delete(e){return this.map.delete(e)}has(e){return this.map.has(e)}clear(){this.map.clear()}keys(){return this.map.keys()}values(){return this.map.values()}entries(){return this.map.entries()}forEach(e,t){this.map.forEach(e,t)}}},741:(__unused_webpack_module,__webpack_exports__,__webpack_require__)=>{__webpack_require__.d(__webpack_exports__,{Ub:()=>HaskellMessageTag,Xq:()=>unknownToJValue,bK:()=>JavaScriptMessageTag,f:()=>mkStartMessage,iI:()=>haskellMessage,r:()=>javascriptMessage,sN:()=>evalExpr});var _binary__WEBPACK_IMPORTED_MODULE_0__=__webpack_require__(268),_lib__WEBPACK_IMPORTED_MODULE_1__=__webpack_require__(849),JValueTag;function Cons(e,t){return[e,t]}function car(e){return e[0]}function cdr(e){return e[1]}function evalExpr(idenScope,argScope,hscb,exp){var _a;switch(exp.tag){case ExprTag.Null:return null;case ExprTag.Boolean:return 0!=exp[0];case ExprTag.Number:return Number(exp.decimal);case ExprTag.String:return exp[0];case ExprTag.Array:return exp[0].map(evalExpr.bind(void 0,idenScope,argScope,hscb));case ExprTag.Object:return Object.fromEntries(exp[0].map((([e,t])=>[e,evalExpr(idenScope,argScope,hscb,t)])));case ExprTag.Uint8Array:return exp[0];case ExprTag.Dot:{const e=evalExpr(idenScope,argScope,hscb,exp[0]);return e[exp[1]]}case ExprTag.AssignProp:{const e=evalExpr(idenScope,argScope,hscb,exp[2]),t=evalExpr(idenScope,argScope,hscb,exp[0]);return t[exp[1]]=e,e}case ExprTag.Ix:{const e=evalExpr(idenScope,argScope,hscb,exp.exp);return e[exp.ix]}case ExprTag.Add:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e+t}case ExprTag.Subtract:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e-t}case ExprTag.Multiply:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e*t}case ExprTag.Divide:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e/t}case ExprTag.Id:{const e=exp[0];for(let t=idenScope;t;t=cdr(t)){const r=car(t);if(e in r)return r[e]}throw new Error(\"Variable not in scope: \"+exp[0])}case ExprTag.Lam:return function(){return evalExpr(idenScope,Cons(arguments,argScope),hscb,exp.body)};case ExprTag.Arg:{let e=argScope,t=0;for(;e;){if(t==exp.scopeIx){const t=car(e);return t[exp.argIx]}e=cdr(e),t++}throw new Error(\"Argument scope out of a range: \"+exp.scopeIx)}case ExprTag.Apply:{const e=evalExpr(idenScope,argScope,hscb,exp[0]);return e.apply(void 0,exp[1].map(evalExpr.bind(void 0,idenScope,argScope,hscb)))}case ExprTag.Call:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=e[exp[1]];return t.apply(e,exp[2].map(evalExpr.bind(void 0,idenScope,argScope,hscb)))}case ExprTag.AssignVar:{const e=evalExpr(idenScope,argScope,hscb,exp.rhs);if(varStorage.has(exp.scopeId)){const t=varStorage.get(exp.scopeId);t.set(exp.varId,e)}else{const t=new Map;t.set(exp.varId,e),varStorage.set(exp.scopeId,t)}return e}case ExprTag.FreeVar:{const e=varStorage.get(exp.scopeId);if(!e)return;return e.delete(exp.varId),void(0==e.size&&varStorage.delete(exp.scopeId))}case ExprTag.Var:return null===(_a=varStorage.get(exp.scopeId))||void 0===_a?void 0:_a.get(exp.varId);case ExprTag.FreeScope:{varStorage.delete(exp.scopeId);const e=finalizers.get(exp.scopeId);return e&&e.forEach((e=>e())),null}case ExprTag.InsertNode:{const e=evalExpr(idenScope,argScope,hscb,exp.parent),t=evalExpr(idenScope,argScope,hscb,exp.child);return domHelpers.insertIntoBuilder(e,t),null}case ExprTag.WithDomBuilder:{const e=evalExpr(idenScope,argScope,hscb,exp.dest),t=evalExpr(idenScope,argScope,hscb,exp.builderFn);return t(e),e}case ExprTag.CreateElement:return document.createElement(exp.tagName);case ExprTag.CreateElementNS:return document.createElementNS(exp.ns,exp.tagName);case ExprTag.CreateText:return document.createTextNode(exp.content);case ExprTag.ElementProp:{const e=evalExpr(idenScope,argScope,hscb,exp.node),t=evalExpr(idenScope,argScope,hscb,exp.propValue);return domHelpers.assignProperty(e,exp.propName,t),null}case ExprTag.ElementAttr:{const e=evalExpr(idenScope,argScope,hscb,exp.node);return domHelpers.assignAttribute(e,exp.attrName,exp.attrValue),null}case ExprTag.InsertClassList:{const e=evalExpr(idenScope,argScope,hscb,exp.node),t=domHelpers.domBuilderElement(e);return exp.classList.forEach((e=>t.classList.add(e))),null}case ExprTag.RemoveClassList:{const e=evalExpr(idenScope,argScope,hscb,exp.node),t=domHelpers.domBuilderElement(e);return exp.classList.forEach((e=>t.classList.remove(e))),null}case ExprTag.AssignText:{const e=evalExpr(idenScope,argScope,hscb,exp.node);return e.textContent=exp.content,null}case ExprTag.InsertBoundary:{const e=evalExpr(idenScope,argScope,hscb,exp.parent);return domHelpers.insertBoundary(e)}case ExprTag.ClearBoundary:{const e=evalExpr(idenScope,argScope,hscb,exp.boundary);return domHelpers.clearBoundary(e,Boolean(exp.detach))}case ExprTag.AddEventListener:{const e=evalExpr(idenScope,argScope,hscb,exp.target),t=evalExpr(idenScope,argScope,hscb,exp.eventName),r=evalExpr(idenScope,argScope,hscb,exp.listener);domHelpers.addEventListener(e,t,r);const _=finalizers.get(exp.reactiveScope),n=_||new _lib__WEBPACK_IMPORTED_MODULE_1__.O;return _||finalizers.set(exp.reactiveScope,n),n.push((()=>domHelpers.removeEventListener(e,t,r)))}case ExprTag.SetTimeout:{const e=evalExpr(idenScope,argScope,hscb,exp.callback),t=finalizers.get(exp.reactiveScope),r=t||new _lib__WEBPACK_IMPORTED_MODULE_1__.O;t||finalizers.set(exp.reactiveScope,r);let _=null;const n=r.push((()=>_&&clearTimeout(_)));return _=setTimeout((()=>{r.delete(n),_=null,e()}),exp.timeout),n}case ExprTag.ApplyFinalizer:{const e=finalizers.get(exp.reactiveScope),t=evalExpr(idenScope,argScope,hscb,exp.finalizerId);if(!e)return!1;const r=e.get(t);return!!r&&(e.delete(t),r(),!0)}case ExprTag.RevSeq:return exp.exprs.reduceRight(((e,t)=>evalExpr(idenScope,argScope,hscb,t)),null);case ExprTag.Eval:return eval(exp.rawJavaScript);case ExprTag.TriggerEvent:{const e=evalExpr(idenScope,argScope,hscb,exp.arg),t={tag:JavaScriptMessageTag.TriggerEvent,arg:unknownToJValue(e),callbackId:exp.callbackId};return hscb(t,argScope)}case ExprTag.TriggerAnimation:{const e=evalExpr(idenScope,argScope,hscb,exp.arg),t={tag:JavaScriptMessageTag.TriggerAnimation,arg:unknownToJValue(e),callbackId:exp.callbackId};return hscb(t,argScope)}case ExprTag.TriggerCallback:{const e=evalExpr(idenScope,argScope,hscb,exp.arg),t={tag:JavaScriptMessageTag.TriggerCallback,arg:unknownToJValue(e),callbackId:exp.callbackId};return hscb(t,argScope)}case ExprTag.UncaughtException:throw new Error(exp.message)}(0,_lib__WEBPACK_IMPORTED_MODULE_1__.R)(exp)}function unknownToJValue(e){if(\"boolean\"==typeof e)return{tag:JValueTag.Boolean,0:e?1:0};if(\"number\"==typeof e){const t=e.toString();return{tag:JValueTag.Number,decimal:t}}if(\"string\"==typeof e)return{tag:JValueTag.String,0:e};if(Array.isArray(e))return{tag:JValueTag.Array,0:e.map(unknownToJValue)};if(e instanceof Uint8Array)return{tag:JValueTag.Uint8Array,0:e};if(null==e)return{tag:JValueTag.Null};const t=Object.entries(e).map((([e,t])=>[e,unknownToJValue(t)]));return{tag:JValueTag.Object,0:t}}!function(e){e[e.Null=0]=\"Null\",e[e.Boolean=1]=\"Boolean\",e[e.Number=2]=\"Number\",e[e.String=3]=\"String\",e[e.Array=4]=\"Array\",e[e.Object=5]=\"Object\",e[e.Uint8Array=6]=\"Uint8Array\"}(JValueTag||(JValueTag={}));const jvalue=_binary__WEBPACK_IMPORTED_MODULE_0__.BE((e=>_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[JValueTag.Null]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({}),[JValueTag.Boolean]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[JValueTag.Number]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({decimal:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[JValueTag.String]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[JValueTag.Array]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[JValueTag.Object]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(_binary__WEBPACK_IMPORTED_MODULE_0__.bc(_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,e))}),[JValueTag.Uint8Array]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.qZ})}))),startLocation=_binary__WEBPACK_IMPORTED_MODULE_0__.IM({protocol:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,hostname:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,port:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,pathname:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,search:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,hash:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),startFlags=_binary__WEBPACK_IMPORTED_MODULE_0__.IM({initial_url:startLocation,window_inner_size:_binary__WEBPACK_IMPORTED_MODULE_0__.bc(_binary__WEBPACK_IMPORTED_MODULE_0__.a2,_binary__WEBPACK_IMPORTED_MODULE_0__.a2),devserver_connection_id:_binary__WEBPACK_IMPORTED_MODULE_0__.wY(_binary__WEBPACK_IMPORTED_MODULE_0__.a2)});var ExprTag;!function(e){e[e.Null=0]=\"Null\",e[e.Boolean=1]=\"Boolean\",e[e.Number=2]=\"Number\",e[e.String=3]=\"String\",e[e.Array=4]=\"Array\",e[e.Object=5]=\"Object\",e[e.Uint8Array=6]=\"Uint8Array\",e[e.Dot=7]=\"Dot\",e[e.AssignProp=8]=\"AssignProp\",e[e.Ix=9]=\"Ix\",e[e.Add=10]=\"Add\",e[e.Subtract=11]=\"Subtract\",e[e.Multiply=12]=\"Multiply\",e[e.Divide=13]=\"Divide\",e[e.Id=14]=\"Id\",e[e.Lam=15]=\"Lam\",e[e.Arg=16]=\"Arg\",e[e.Apply=17]=\"Apply\",e[e.Call=18]=\"Call\",e[e.AssignVar=19]=\"AssignVar\",e[e.FreeVar=20]=\"FreeVar\",e[e.Var=21]=\"Var\",e[e.FreeScope=22]=\"FreeScope\",e[e.InsertNode=23]=\"InsertNode\",e[e.WithDomBuilder=24]=\"WithDomBuilder\",e[e.CreateElement=25]=\"CreateElement\",e[e.CreateElementNS=26]=\"CreateElementNS\",e[e.CreateText=27]=\"CreateText\",e[e.ElementProp=28]=\"ElementProp\",e[e.ElementAttr=29]=\"ElementAttr\",e[e.InsertClassList=30]=\"InsertClassList\",e[e.RemoveClassList=31]=\"RemoveClassList\",e[e.AssignText=32]=\"AssignText\",e[e.InsertBoundary=33]=\"InsertBoundary\",e[e.ClearBoundary=34]=\"ClearBoundary\",e[e.AddEventListener=35]=\"AddEventListener\",e[e.SetTimeout=36]=\"SetTimeout\",e[e.ApplyFinalizer=37]=\"ApplyFinalizer\",e[e.RevSeq=38]=\"RevSeq\",e[e.Eval=39]=\"Eval\",e[e.TriggerEvent=40]=\"TriggerEvent\",e[e.TriggerAnimation=41]=\"TriggerAnimation\",e[e.TriggerCallback=42]=\"TriggerCallback\",e[e.UncaughtException=43]=\"UncaughtException\"}(ExprTag||(ExprTag={}));const expr=_binary__WEBPACK_IMPORTED_MODULE_0__.BE((e=>_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[ExprTag.Null]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({}),[ExprTag.Boolean]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.Number]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({decimal:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.String]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.Array]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.Object]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(_binary__WEBPACK_IMPORTED_MODULE_0__.bc(_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,e))}),[ExprTag.Dot]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.AssignProp]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,2:e}),[ExprTag.Ix]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({exp:e,ix:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.Add]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Subtract]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Multiply]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Divide]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Id]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.Lam]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({body:e}),[ExprTag.Arg]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeIx:_binary__WEBPACK_IMPORTED_MODULE_0__.cS,argIx:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.Apply]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.Call]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,2:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.AssignVar]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,varId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,rhs:e}),[ExprTag.FreeVar]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,varId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.Var]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,varId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.FreeScope]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.InsertNode]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({parent:e,child:e}),[ExprTag.WithDomBuilder]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({dest:e,builderFn:e}),[ExprTag.CreateElement]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({tagName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.CreateElementNS]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({ns:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,tagName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.CreateText]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({content:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.ElementProp]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,propName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,propValue:e}),[ExprTag.ElementAttr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,attrName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,attrValue:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.InsertClassList]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,classList:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(_binary__WEBPACK_IMPORTED_MODULE_0__.Z_)}),[ExprTag.RemoveClassList]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,classList:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(_binary__WEBPACK_IMPORTED_MODULE_0__.Z_)}),[ExprTag.AssignText]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,content:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.InsertBoundary]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({parent:e}),[ExprTag.ClearBoundary]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({boundary:e,detach:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.AddEventListener]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({reactiveScope:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,target:e,eventName:e,listener:e}),[ExprTag.SetTimeout]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({reactiveScope:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,callback:e,timeout:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.ApplyFinalizer]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({reactiveScope:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,finalizerId:e}),[ExprTag.RevSeq]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({exprs:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.Eval]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({rawJavaScript:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.TriggerEvent]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,arg:e}),[ExprTag.TriggerAnimation]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,arg:e}),[ExprTag.TriggerCallback]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,arg:e}),[ExprTag.UncaughtException]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({message:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_})})));var HaskellMessageTag;!function(e){e[e.EvalExpr=0]=\"EvalExpr\",e[e.Yield=1]=\"Yield\",e[e.HotReload=2]=\"HotReload\",e[e.Done=3]=\"Done\"}(HaskellMessageTag||(HaskellMessageTag={}));const haskellMessage=_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[HaskellMessageTag.EvalExpr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({expr}),[HaskellMessageTag.Yield]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({expr}),[HaskellMessageTag.HotReload]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({}),[HaskellMessageTag.Done]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({})});var JavaScriptMessageTag;!function(e){e[e.Start=0]=\"Start\",e[e.Return=1]=\"Return\",e[e.TriggerEvent=2]=\"TriggerEvent\",e[e.TriggerAnimation=3]=\"TriggerAnimation\",e[e.TriggerCallback=4]=\"TriggerCallback\",e[e.BeforeUnload=5]=\"BeforeUnload\"}(JavaScriptMessageTag||(JavaScriptMessageTag={}));const javascriptMessage=_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[JavaScriptMessageTag.Start]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({startFlags}),[JavaScriptMessageTag.Return]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:jvalue}),[JavaScriptMessageTag.TriggerEvent]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({arg:jvalue,callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[JavaScriptMessageTag.TriggerAnimation]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({arg:jvalue,callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[JavaScriptMessageTag.TriggerCallback]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({arg:jvalue,callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[JavaScriptMessageTag.BeforeUnload]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({})}),varStorage=new Map,finalizers=new Map;function mkStartMessage(){const e={protocol:location.protocol,hostname:location.hostname,port:location.port,pathname:location.pathname,search:location.search,hash:location.hash};return{tag:JavaScriptMessageTag.Start,startFlags:{initial_url:e,window_inner_size:[window.innerWidth,window.innerHeight],devserver_connection_id:{tag:_binary__WEBPACK_IMPORTED_MODULE_0__.OZ.Nothing}}}}var domHelpers;!function(e){function t(e,t){e instanceof Comment?e.parentElement.insertBefore(t,e):e.appendChild(t)}function r(e){return e instanceof Comment?e.parentElement:e}function _(e){return e instanceof Comment&&\"ContentBoundary {{\"==e.textContent}e.insertIntoBuilder=t,e.assignProperty=function(e,t,r){e instanceof Comment?e.parentElement[t]=r:e[t]=r},e.assignAttribute=function(e,t,_){r(e).setAttribute(t,_)},e.addEventListener=function(e,t,_){r(e).addEventListener(t,_)},e.removeEventListener=function(e,t,_){r(e).removeEventListener(t,_)},e.insertBoundary=function(e){const r=document.createComment(\"ContentBoundary {{\"),_=document.createComment(\"}}\");return t(e,r),t(e,_),_},e.clearBoundary=function(e,t){const r=e;let n=0;for(;r.previousSibling&&(0!=n||!_(r.previousSibling));)(a=r.previousSibling)instanceof Comment&&\"}}\"==a.textContent?n++:_(r.previousSibling)&&n--,r.previousSibling.parentNode.removeChild(r.previousSibling);var a;t&&(r.previousSibling.parentNode.removeChild(r.previousSibling),r.parentNode.removeChild(r))},e.domBuilderElement=r}(domHelpers||(domHelpers={}))}},__webpack_module_cache__={};function __webpack_require__(e){var t=__webpack_module_cache__[e];if(void 0!==t)return t.exports;var r=__webpack_module_cache__[e]={exports:{}};return __webpack_modules__[e](r,r.exports,__webpack_require__),r.exports}__webpack_require__.d=(e,t)=>{for(var r in t)__webpack_require__.o(t,r)&&!__webpack_require__.o(e,r)&&Object.defineProperty(e,r,{enumerable:!0,get:t[r]})},__webpack_require__.o=(e,t)=>Object.prototype.hasOwnProperty.call(e,t);var __webpack_exports__={};(()=>{function e(e,t,r,_){return new(r||(r=Promise))((function(n,a){function s(e){try{o(_.next(e))}catch(e){a(e)}}function i(e){try{o(_.throw(e))}catch(e){a(e)}}function o(e){var t;e.done?n(e.value):(t=e.value,t instanceof r?t:new r((function(e){e(t)}))).then(s,i)}o((_=_.apply(e,t||[])).next())}))}Object.create,Object.create,\"function\"==typeof SuppressedError&&SuppressedError;class t{static read_bytes(e,r){let _=new t;return _.buf=e.getUint32(r,!0),_.buf_len=e.getUint32(r+4,!0),_}static read_bytes_array(e,r,_){let n=[];for(let a=0;a<_;a++)n.push(t.read_bytes(e,r+8*a));return n}}class r{static read_bytes(e,t){let _=new r;return _.buf=e.getUint32(t,!0),_.buf_len=e.getUint32(t+4,!0),_}static read_bytes_array(e,t,_){let n=[];for(let a=0;a<_;a++)n.push(r.read_bytes(e,t+8*a));return n}}class _{write_bytes(e,t){e.setUint8(t,this.fs_filetype),e.setUint16(t+2,this.fs_flags,!0),e.setBigUint64(t+8,this.fs_rights_base,!0),e.setBigUint64(t+16,this.fs_rights_inherited,!0)}constructor(e,t){this.fs_rights_base=0n,this.fs_rights_inherited=0n,this.fs_filetype=e,this.fs_flags=t}}class n{write_bytes(e,t){e.setBigUint64(t,this.dev,!0),e.setBigUint64(t+8,this.ino,!0),e.setUint8(t+16,this.filetype),e.setBigUint64(t+24,this.nlink,!0),e.setBigUint64(t+32,this.size,!0),e.setBigUint64(t+38,this.atim,!0),e.setBigUint64(t+46,this.mtim,!0),e.setBigUint64(t+52,this.ctim,!0)}constructor(e,t){this.dev=0n,this.ino=0n,this.nlink=0n,this.atim=0n,this.mtim=0n,this.ctim=0n,this.filetype=e,this.size=t}}class a{fd_advise(e,t,r){return-1}fd_allocate(e,t){return-1}fd_close(){return 0}fd_datasync(){return-1}fd_fdstat_get(){return{ret:-1,fdstat:null}}fd_fdstat_set_flags(e){return-1}fd_fdstat_set_rights(e,t){return-1}fd_filestat_get(){return{ret:-1,filestat:null}}fd_filestat_set_size(e){return-1}fd_filestat_set_times(e,t,r){return-1}fd_pread(e,t,r){return{ret:-1,nread:0}}fd_prestat_get(){return{ret:-1,prestat:null}}fd_prestat_dir_name(e,t){return{ret:-1,prestat_dir_name:null}}fd_pwrite(e,t,r){return{ret:-1,nwritten:0}}fd_read(e,t){return{ret:-1,nread:0}}fd_readdir_single(e){return{ret:-1,dirent:null}}fd_seek(e,t){return{ret:-1,offset:0n}}fd_sync(){return 0}fd_tell(){return{ret:-1,offset:0n}}fd_write(e,t){return{ret:-1,nwritten:0}}path_create_directory(e){return-1}path_filestat_get(e,t){return{ret:-1,filestat:null}}path_filestat_set_times(e,t,r,_,n){return-1}path_link(e,t,r,_){return-1}path_open(e,t,r,_,n,a){return{ret:-1,fd_obj:null}}path_readlink(e){return{ret:-1,data:null}}path_remove_directory(e){return-1}path_rename(e,t,r){return-1}path_symlink(e,t){return-1}path_unlink_file(e){return-1}}class s extends a{fd_fdstat_get(){return{ret:0,fdstat:new _(4,0)}}fd_read(e,t){let r=0;for(let _ of t){if(!(this.file_pos<this.file.data.byteLength))break;{let t=this.file.data.slice(Number(this.file_pos),Number(this.file_pos+BigInt(_.buf_len)));e.set(t,_.buf),this.file_pos+=BigInt(t.length),r+=t.length}}return{ret:0,nread:r}}fd_seek(e,t){let r;switch(t){case 0:r=e;break;case 1:r=this.file_pos+e;break;case 2:r=BigInt(this.file.data.byteLength)+e;break;default:return{ret:28,offset:0n}}return r<0?{ret:28,offset:0n}:(this.file_pos=r,{ret:0,offset:this.file_pos})}fd_write(e,t){let r=0;if(this.file.readonly)return{ret:8,nwritten:r};for(let _ of t){let t=e.slice(_.buf,_.buf+_.buf_len);if(this.file_pos+BigInt(t.byteLength)>this.file.size){let e=this.file.data;this.file.data=new Uint8Array(Number(this.file_pos+BigInt(t.byteLength))),this.file.data.set(e)}this.file.data.set(t.slice(0,Number(this.file.size-this.file_pos)),Number(this.file_pos)),this.file_pos+=BigInt(t.byteLength),r+=_.buf_len}return{ret:0,nwritten:r}}fd_filestat_get(){return{ret:0,filestat:this.file.stat()}}constructor(e){super(),this.file_pos=0n,this.file=e}}class i{open(e){let t=new s(this);return 1&e&&t.fd_seek(0n,2),t}get size(){return BigInt(this.data.byteLength)}stat(){return new n(4,this.size)}truncate(){return this.readonly?63:(this.data=new Uint8Array([]),0)}constructor(e,t){this.data=new Uint8Array(e),this.readonly=!!t?.readonly}}var o=__webpack_require__(849),l=__webpack_require__(741);function c(e,t,r=null){const _=t||l.f(),n=function(e,t){const r=function(e,t){const r=t.byteLength,_=e.exports.hs_malloc(t.length+8);return new DataView(e.exports.memory.buffer).setUint32(_,r,!0),new Uint8Array(e.exports.memory.buffer,_+8,r).set(t),_}(e,l.r.encode(t)),_=function(e,t){const r=new Uint8Array(e.exports.memory.buffer,t),_=r[0]+(r[1]<<8)+(r[2]<<16)+(r[3]<<24)+(r[4]<<32)+(r[5]<<40)+(r[6]<<48)+(r[7]<<56),n=new Uint8Array(e.exports.memory.buffer,t+8,_).slice().buffer;return e.exports.hs_free(t),new Uint8Array(n)}(e,e.exports.app(r));return l.iI.decode(_)}(e,_),a=(t,r)=>{c(e,t,r)};switch(n.tag){case l.Ub.EvalExpr:{const t=l.sN(p,r,a,n.expr),_=l.Xq(t);return c(e,{tag:l.bK.Return,0:_},r)}case l.Ub.Yield:return void l.sN(p,r,a,n.expr);case l.Ub.HotReload:return void window.location.reload();case l.Ub.Done:return}(0,o.R)(n)}const p=[window,null];class u extends s{constructor(e,t){super(e),this.printDebug=t}fd_write(e,t){const r=super.fd_write(e,t);return t.forEach((r=>{this.printDebug(e.subarray(t[0].buf,r.buf+r.buf_len))})),r}}function E(e){let t=[];return r=>{const _=r=>{if(0==r.byteLength)return;const n=r.findIndex((e=>e==\"\\n\".charCodeAt(0)));if(n>=0){const a=t.map((e=>new TextDecoder(\"utf8\").decode(e))).join(\"\");t=[];const s=new TextDecoder(\"utf8\").decode(r.subarray(0,n));e(a+s),_(r.subarray(n+1))}else t.push(r.slice())};_(r)}}function d(t,r,_){return e(this,void 0,void 0,(function*(){switch(t.tag){case l.Ub.EvalExpr:{const e=l.sN(f,r,_,t.expr),n=l.Xq(e);return _({tag:l.bK.Return,0:n},r)}case l.Ub.Yield:return void l.sN(f,r,_,t.expr);case l.Ub.HotReload:return void window.location.reload();case l.Ub.Done:return}(0,o.R)(t)}))}const f=[window,null];function g(e){return new Promise(((t,r)=>{const _=new FileReader;_.onload=()=>{const e=_.result,r=new Uint8Array(e);t(r)},_.onerror=e=>{r(e)},_.readAsArrayBuffer(e)}))}window.startReactor=function(_,n={}){return e(this,void 0,void 0,(function*(){const e=E(console.log),n=E(console.log),a=new class{start(e){this.inst=e,e.exports._start()}initialize(e){this.inst=e,e.exports._initialize()}constructor(e,_,n){this.args=[],this.env=[],this.fds=[],this.args=e,this.env=_,this.fds=n;let a=this;this.wasiImport={args_sizes_get(e,t){let r=new DataView(a.inst.exports.memory.buffer);r.setUint32(e,a.args.length,!0);let _=0;for(let e of a.args)_+=e.length+1;return r.setUint32(t,_,!0),0},args_get(e,t){let r=new DataView(a.inst.exports.memory.buffer),_=new Uint8Array(a.inst.exports.memory.buffer);for(let n=0;n<a.args.length;n++){r.setUint32(e,t,!0),e+=4;let s=new TextEncoder(\"utf-8\").encode(a.args[n]);_.set(s,t),r.setUint8(t+s.length,0),t+=s.length+1}return 0},environ_sizes_get(e,t){let r=new DataView(a.inst.exports.memory.buffer);r.setUint32(e,a.env.length,!0);let _=0;for(let e of a.env)_+=e.length+1;return r.setUint32(t,_,!0),0},environ_get(e,t){let r=new DataView(a.inst.exports.memory.buffer),n=new Uint8Array(a.inst.exports.memory.buffer);for(let a=0;a<_.length;a++){r.setUint32(e,t,!0),e+=4;let s=new TextEncoder(\"utf-8\").encode(_[a]);n.set(s,t),r.setUint8(t+s.length,0),t+=s.length+1}return 0},clock_res_get(e,t){throw\"unimplemented\"},clock_time_get(e,t,r){let _=new DataView(a.inst.exports.memory.buffer);if(0===e)_.setBigUint64(r,1000000n*BigInt((new Date).getTime()),!0);else if(1==e){let e;try{e=BigInt(Math.round(1e6*performance.now()))}catch(t){e=0n}_.setBigUint64(r,e,!0)}else _.setBigUint64(r,0n,!0);return 0},fd_advise:(e,t,r,_)=>null!=a.fds[e]?a.fds[e].fd_advise(t,r,_):8,fd_allocate:(e,t,r)=>null!=a.fds[e]?a.fds[e].fd_allocate(t,r):8,fd_close(e){if(null!=a.fds[e]){let t=a.fds[e].fd_close();return a.fds[e]=void 0,t}return 8},fd_datasync:e=>null!=a.fds[e]?a.fds[e].fd_datasync():8,fd_fdstat_get(e,t){if(null!=a.fds[e]){let{ret:r,fdstat:_}=a.fds[e].fd_fdstat_get();return null!=_&&_.write_bytes(new DataView(a.inst.exports.memory.buffer),t),r}return 8},fd_fdstat_set_flags:(e,t)=>null!=a.fds[e]?a.fds[e].fd_fdstat_set_flags(t):8,fd_fdstat_set_rights:(e,t,r)=>null!=a.fds[e]?a.fds[e].fd_fdstat_set_rights(t,r):8,fd_filestat_get(e,t){if(null!=a.fds[e]){let{ret:r,filestat:_}=a.fds[e].fd_filestat_get();return null!=_&&_.write_bytes(new DataView(a.inst.exports.memory.buffer),t),r}return 8},fd_filestat_set_size:(e,t)=>null!=a.fds[e]?a.fds[e].fd_filestat_set_size(t):8,fd_filestat_set_times:(e,t,r,_)=>null!=a.fds[e]?a.fds[e].fd_filestat_set_times(t,r,_):8,fd_pread(e,r,_,n,s){let i=new DataView(a.inst.exports.memory.buffer),o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=t.read_bytes_array(i,r,_),{ret:c,nread:p}=a.fds[e].fd_pread(o,l,n);return i.setUint32(s,p,!0),c}return 8},fd_prestat_get(e,t){let r=new DataView(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let{ret:_,prestat:n}=a.fds[e].fd_prestat_get();return null!=n&&n.write_bytes(r,t),_}return 8},fd_prestat_dir_name(e,t,r){if(null!=a.fds[e]){let{ret:r,prestat_dir_name:_}=a.fds[e].fd_prestat_dir_name();return null!=_&&new Uint8Array(a.inst.exports.memory.buffer).set(_,t),r}return 8},fd_pwrite(e,t,_,n,s){let i=new DataView(a.inst.exports.memory.buffer),o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=r.read_bytes_array(i,t,_),{ret:c,nwritten:p}=a.fds[e].fd_pwrite(o,l,n);return i.setUint32(s,p,!0),c}return 8},fd_read(e,r,_,n){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=t.read_bytes_array(s,r,_),{ret:l,nread:c}=a.fds[e].fd_read(i,o);return s.setUint32(n,c,!0),l}return 8},fd_readdir(e,t,r,_,n){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=0;for(;;){let{ret:l,dirent:c}=a.fds[e].fd_readdir_single(_);if(0!=l)return s.setUint32(n,o,!0),l;if(null==c)break;if(r-o<c.head_length()){o=r;break}let p=new ArrayBuffer(c.head_length());if(c.write_head_bytes(new DataView(p),0),i.set(new Uint8Array(p).slice(0,Math.min(p.byteLength,r-o)),t),t+=c.head_length(),o+=c.head_length(),r-o<c.name_length()){o=r;break}c.write_name_bytes(i,t,r-o),t+=c.name_length(),o+=c.name_length(),_=c.d_next}return s.setUint32(n,o,!0),0}return 8},fd_renumber(e,t){if(null!=a.fds[e]&&null!=a.fds[t]){let r=a.fds[t].fd_close();return 0!=r?r:(a.fds[t]=a.fds[e],a.fds[e]=void 0,0)}return 8},fd_seek(e,t,r,_){let n=new DataView(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let{ret:s,offset:i}=a.fds[e].fd_seek(t,r);return n.setBigInt64(_,i,!0),s}return 8},fd_sync:e=>null!=a.fds[e]?a.fds[e].fd_sync():8,fd_tell(e,t){let r=new DataView(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let{ret:_,offset:n}=a.fds[e].fd_tell();return r.setBigUint64(t,n,!0),_}return 8},fd_write(e,t,_,n){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=r.read_bytes_array(s,t,_),{ret:l,nwritten:c}=a.fds[e].fd_write(i,o);return s.setUint32(n,c,!0),l}return 8},path_create_directory(e,t,r){let _=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let n=new TextDecoder(\"utf-8\").decode(_.slice(t,t+r));return a.fds[e].path_create_directory(n)}},path_filestat_get(e,t,r,_,n){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=new TextDecoder(\"utf-8\").decode(i.slice(r,r+_)),{ret:l,filestat:c}=a.fds[e].path_filestat_get(t,o);return null!=c&&c.write_bytes(s,n),l}return 8},path_filestat_set_times(e,t,r,_,n,s,i){let o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=new TextDecoder(\"utf-8\").decode(o.slice(r,r+_));return a.fds[e].path_filestat_set_times(t,l,n,s,i)}return 8},path_link(e,t,r,_,n,s,i){let o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]&&null!=a.fds[n]){let l=new TextDecoder(\"utf-8\").decode(o.slice(r,r+_)),c=new TextDecoder(\"utf-8\").decode(o.slice(s,s+i));return a.fds[n].path_link(e,t,l,c)}return 8},path_open(e,t,r,_,n,s,i,o,l){let c=new DataView(a.inst.exports.memory.buffer),p=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let u=new TextDecoder(\"utf-8\").decode(p.slice(r,r+_)),{ret:E,fd_obj:d}=a.fds[e].path_open(t,u,n,s,i,o);if(0!=E)return E;a.fds.push(d);let f=a.fds.length-1;return c.setUint32(l,f,!0),0}return 8},path_readlink(e,t,r,_,n,s){let i=new DataView(a.inst.exports.memory.buffer),o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=new TextDecoder(\"utf-8\").decode(o.slice(t,t+r)),{ret:c,data:p}=a.fds[e].path_readlink(l);if(null!=p){if(p.length>n)return i.setUint32(s,0,!0),8;o.set(p,_),i.setUint32(s,p.length,!0)}return c}return 8},path_remove_directory(e,t,r){let _=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let n=new TextDecoder(\"utf-8\").decode(_.slice(t,t+r));return a.fds[e].path_remove_directory(n)}return 8},path_rename(e,t,r,_,n,a){throw\"FIXME what is the best abstraction for this?\"},path_symlink(e,t,r,_,n){let s=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[r]){let i=new TextDecoder(\"utf-8\").decode(s.slice(e,e+t)),o=new TextDecoder(\"utf-8\").decode(s.slice(_,_+n));return a.fds[r].path_symlink(i,o)}return 8},path_unlink_file(e,t,r){let _=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let n=new TextDecoder(\"utf-8\").decode(_.slice(t,t+r));return a.fds[e].path_unlink_file(n)}return 8},poll_oneoff(e,t,r){throw\"async io not supported\"},proc_exit(e){throw\"exit with exit code \"+e},proc_raise(e){throw\"raised signal \"+e},sched_yield(){},random_get(e,t){let r=new Uint8Array(a.inst.exports.memory.buffer);for(let _=0;_<t;_++)r[e+_]=256*Math.random()|0},sock_recv(e,t,r){throw\"sockets not supported\"},sock_send(e,t,r){throw\"sockets not supported\"},sock_shutdown(e,t){throw\"sockets not supported\"},sock_accept(e,t){throw\"sockets not supported\"}}}}([],[],[new s(new i([])),new u(new i([]),e),new u(new i([]),n)]),o=yield WebAssembly.compileStreaming(fetch(_)),p=yield WebAssembly.instantiate(o,{wasi_snapshot_preview1:a.wasiImport});a.initialize(p),p.exports.hs_init(),window.addEventListener(\"beforeunload\",(()=>c(p,{tag:l.bK.BeforeUnload}))),c(p)}))},window.startDevClient=function(t){return e(this,void 0,void 0,(function*(){const r=new WebSocket(t),_=(t,n)=>e(this,void 0,void 0,(function*(){r.send(l.r.encode(t));const a=yield function(){return new Promise(((t,_)=>{const n=r.onmessage;r.onmessage=a=>e(this,void 0,void 0,(function*(){r.onmessage=n;try{const e=yield g(a.data),r=l.iI.decode(e);t(r)}catch(e){_(e)}}))}))}();yield d(a,n,_)}));r.onopen=e=>{const t=l.r.encode(l.f());r.send(t)},r.onmessage=t=>e(this,void 0,void 0,(function*(){const e=yield g(t.data);d(l.iI.decode(e),null,_)})),r.onerror=e=>{console.error(\"WebSocket error:\",e)},r.onclose=e=>{console.log(\"WebSocket connection closed:\",e)}}))}})()})();"
