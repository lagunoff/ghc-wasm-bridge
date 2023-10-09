import Control.Monad
import Control.Monad.Reader
import Data.ByteString
import Data.ByteString.Char8 qualified as Char8
import Data.List qualified as List
import Data.Ord
import Data.Text qualified as Text ()
import Data.Text.Encoding qualified as Text
import Data.Word
import Foreign.Marshal.Alloc qualified as Alloc
import Foreign.Ptr

import HtmlT.Wasm

foreign export ccall app :: Ptr Word8 -> IO (Ptr Word8)
app = wasmApp wasmMain
foreign export ccall hs_malloc :: Int -> IO (Ptr a)
hs_malloc = Alloc.callocBytes
foreign export ccall hs_free :: Ptr a -> IO ()
hs_free = Alloc.free

main = return ()

data VotingCandidate = VotingCandidate
  { language :: ByteString
  , votes :: Int
  }

candidates :: [VotingCandidate]
candidates =
  [ VotingCandidate "Python" 100
  , VotingCandidate "JavaScript" 80
  , VotingCandidate "Java" 70
  , VotingCandidate "C++" 60
  , VotingCandidate "C#" 50
  , VotingCandidate "Go" 40
  , VotingCandidate "Rust" 30
  , VotingCandidate "Ruby" 20
  , VotingCandidate "Swift" 10
  , VotingCandidate "Haskell" 423
  ]

wasmMain :: WA ()
wasmMain = do
  domBuilderId <- asks (.dom_builder_id)
  queueExp $ ElInitBuilder domBuilderId (Id "document" `Dot` "body")
  el "link" (rel_ "stylesheet" >> href_ "./awsm.css")
  votingListRef <- newRef $ normalize candidates
  main_ do
    h4_ "Vote for Your Favorite Programming Language"
    p_ $ ol_ do
      simpleList (fromRef votingListRef) \_ix itemRef -> do
        li_ do
          b_ $ dynText $ fmap (.language) (fromRef itemRef)
          span_ $ dynText $ fmap (("votes: " <>) . Char8.pack . show . (.votes)) (fromRef itemRef)
          button_ do
            text (Text.encodeUtf8 "▲")
            on @"click" $ modifyRef votingListRef . upvote . (.language) =<< readRef itemRef
          button_ do
            text (Text.encodeUtf8 "▼")
            on @"click" $ modifyRef votingListRef . downvote . (.language) =<< readRef itemRef
    p_ do
      choiceRef <- newRef "Haskell"
      select_ do
        forM_ candidates \c -> do
          option_ [value_ c.language] $ text c.language
        dynProp "value" $ fromRef choiceRef
        on @"select/change" $ writeRef choiceRef
      button_ do
        text (Text.encodeUtf8 "▲")
        on @"click" $ modifyRef votingListRef . upvote =<< readRef choiceRef
      button_ do
        text (Text.encodeUtf8 "▼")
        on @"click" $ modifyRef votingListRef . downvote =<< readRef choiceRef

normalize :: [VotingCandidate] -> [VotingCandidate]
normalize = List.sortOn (Down . (.votes))

upvote :: ByteString -> [VotingCandidate] -> [VotingCandidate]
upvote l = normalize . modvote succ l

downvote :: ByteString -> [VotingCandidate] -> [VotingCandidate]
downvote l = normalize . modvote pred l

modvote :: (Int -> Int) -> ByteString -> [VotingCandidate] -> [VotingCandidate]
modvote _ _ [] = []
modvote f l (x:xs)
  | x.language == l = x {votes = f x.votes} : xs
  | otherwise = x : upvote l xs