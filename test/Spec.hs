import Parser (parseExpr)
import Translate (translate)
import Interp (execute)

import Data.Char (isSpace)
import Data.Foldable (for_)
import Data.List (isSuffixOf, stripPrefix, dropWhileEnd)
import System.Directory (getDirectoryContents)
import System.FilePath ((</>))
import Test.Hspec

dir :: FilePath
dir = "examples"

main :: IO ()
main = do
  all <- getDirectoryContents dir
  let files = filter (isSuffixOf ".obj") all
  hspec $ do
    describe "Example" $ do
      for_ files $ \f -> it f $ do
        source <- readFile $ dir </> f
        case stripPrefix "-->" $ head $ lines source of
          Just s -> case parseExpr source of
            Right ast -> do
              let result = execute $ translate ast
                  expected = dropWhileEnd isSpace $ dropWhile isSpace s
              show result `shouldBe` expected
            Left err -> error err
          Nothing -> error "no expectation on the first line"
