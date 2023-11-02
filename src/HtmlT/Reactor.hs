module HtmlT.Reactor where

import Data.Binary qualified as Binary
import Data.ByteString as BS
import Data.ByteString.Lazy qualified as BSL
import Data.ByteString.Unsafe qualified as BSU
import Data.IORef
import Data.Word
import Foreign.Marshal.Alloc qualified as Alloc
import Foreign.Marshal.Utils
import Foreign.Ptr
import Foreign.Storable
import System.IO.Unsafe

import "this" HtmlT.Base
import "this" HtmlT.RJS
import "this" HtmlT.Protocol


reactorApp :: (StartFlags -> RJS ()) -> Ptr Word8 -> IO (Ptr Word8)
reactorApp jsMain p = do
  jsMessage <- Binary.decode . BSL.fromStrict <$> loadByteString p
  haskMessage <- handleMessage rjsInstance jsMain jsMessage
  storeByteString $ BSL.toStrict $ Binary.encode haskMessage
  where
    storeByteString :: ByteString -> IO (Ptr a)
    storeByteString bs = do
      let len = BS.length bs
      dest <- Alloc.callocBytes (len + 8)
      poke @Word64 dest (fromIntegral len)
      BSU.unsafeUseAsCStringLen bs $ \(src, _) ->
        copyBytes (dest `plusPtr` 8) src len
      return (castPtr dest)

    loadByteString :: Ptr a -> IO ByteString
    loadByteString ptr = do
      len <- peek @Word64 (castPtr ptr)
      let contentPtr = ptr `plusPtr` 8
      BSU.unsafePackCStringFinalizer contentPtr (fromIntegral len) (Alloc.free ptr)

rjsInstance :: RjsInstance
rjsInstance = unsafePerformIO do
  rjs_state_ref <- newIORef emptyRjsState
  continuations_ref <- newIORef []
  return RjsInstance {rjs_state_ref, continuations_ref}
