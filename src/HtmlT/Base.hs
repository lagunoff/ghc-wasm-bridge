module HtmlT.Base where

import Control.Exception
import Control.Monad
import Control.Monad.State
import Data.IORef
import Data.Map qualified as Map
import Data.Set qualified as Set
import GHC.Exts
import GHC.Generics
import Unsafe.Coerce

import "this" HtmlT.Event
import "this" HtmlT.JSM
import "this" HtmlT.Protocol
import "this" HtmlT.Protocol.Utf8 qualified as Utf8


data WasmInstance = WasmInstance
  { continuations_ref :: IORef [JValue -> JSM Any]
  , wasm_state_ref :: IORef JSMState
  } deriving (Generic)

runUntillInterruption :: WasmInstance -> JSMEnv -> JSM a -> IO (Either Expr a)
runUntillInterruption opt e wasm = do
  s0 <- readIORef opt.wasm_state_ref
  (s1, result) <- unJSM wasm e s0 `catch` \(e :: SomeException) ->
    -- UncaughtException command never returns a value from JS side,
    -- therefore we can coerce the result to any type
    pure (s0, coerceResult (Cmd (UncaughtException (Utf8.pack (show e)))))
  let
    g :: forall a. JSMResult a -> IO (Either Expr a)
    g r = case r of
      Pure a -> return (Right a)
      Cmd cmd -> return (Left cmd)
      FMap f i -> fmap (fmap f) (g i)
      Interrupt cmd cont -> do
        modifyIORef' opt.continuations_ref (unsafeCoerce cont :)
        return $ Left cmd
  writeIORef opt.wasm_state_ref s1 {evaluation_queue = []}
  eexpr <- g result
  case eexpr of
    Left e ->
      return $ Left $ RevSeq $ e:s1.evaluation_queue
    Right a
      | [] <- s1.evaluation_queue -> return $ Right a
      | otherwise -> do
        let cont (_::JValue) = return (unsafeCoerce a)
        modifyIORef' opt.continuations_ref (cont:)
        return $ Left $ RevSeq s1.evaluation_queue
  where
    coerceResult :: forall a b. JSMResult a -> JSMResult b
    coerceResult = unsafeCoerce

handleMessage :: WasmInstance -> (StartFlags -> JSM ()) -> JavaScriptMessage -> IO HaskellMessage
handleMessage opt wasmMain = \case
  Start startFlags -> do
    writeIORef opt.continuations_ref []
    writeIORef opt.wasm_state_ref JSMState
      { var_storage = Set.fromList [0, 1]
      , evaluation_queue = []
      , subscriptions = Map.empty
      , finalizers = Map.empty
      , id_supply = 0
      , transaction_queue = Map.empty
      }
    result <- runUntillInterruption opt wasmEnv (wasmMain startFlags)
    case result of
      Left exp -> return $ EvalExpr exp
      Right () -> return Exit
  Return jval -> do
    tipCont <- atomicModifyIORef' opt.continuations_ref \case
      [] -> ([], Nothing)
      x:xs -> (xs, Just x)
    case tipCont of
      Nothing ->
        return $ EvalExpr $ UncaughtException "Protocol violation: continuation is missing"
      Just c -> do
        result <- runUntillInterruption opt wasmEnv (c jval)
        case result of
          Left exp -> return $ EvalExpr exp
          Right _ -> return Exit
  ExecCallbackCommand arg callbackId -> do
    let
      eventId = EventId (QueueId (unCallbackId callbackId))
      wasm = unsafeTrigger eventId arg
    result <- runUntillInterruption opt wasmEnv (dynStep wasm)
    case result of
      Left exp -> return $ EvalExpr exp
      Right _ -> return Exit
  BeforeUnload -> do
    result <- runUntillInterruption opt wasmEnv (finalizeNamespace wasmEnv.finalizer_ns)
    case result of
      Left exp -> return $ EvalExpr exp
      Right _ -> return Exit
  where
    wasmEnv = JSMEnv (-1)
