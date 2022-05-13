module Main where

import Parser (parseExpr)
import Translate (translate)
import Interp (execute)

import System.Environment (getArgs)
import System.Exit (exitSuccess)
import Control.Monad.State.Strict (MonadIO(..))
import Data.List (isPrefixOf)

import System.Console.Repline


type Repl a = HaskelineT IO a

throwErr :: Show e => Either e a -> Repl a
throwErr (Left err) = do
  liftIO $ print err
  abort
throwErr (Right val) = return val

-- Execution
exec :: String -> Repl ()
exec source = do
  ast <- throwErr $ parseExpr source
  let val = execute $ translate ast
  liftIO $ print val

-- :load command
load :: String -> Repl ()
load args = do
  contents <- liftIO $ readFile args
  exec contents

-- :quit command
quit :: a -> Repl ()
quit _ = liftIO exitSuccess

-- Prefix tab completer
defaultMatcher :: MonadIO m => [(String, CompletionFunc m)]
defaultMatcher = [(":load", fileCompleter)]

-- Default tab completer
comp :: Monad m => WordCompleter m
comp n = do
  let cmds = [":load", ":quit"]
  return $ filter (isPrefixOf n) cmds

-- List of options and commands
opts :: [(String, String -> Repl ())]
opts = [ ("load", load)
       , ("quit", quit)
       ]


repl :: Repl () -> IO ()
repl ini = evalReplOpts $ ReplOpts
  { banner           = const $ return "REPL> "
  , command          = exec
  , options          = opts
  , prefix           = Just ':'
  , multilineCommand = Nothing
  , tabComplete      = Prefix (wordCompleter comp) defaultMatcher
  , initialiser      = ini
  , finaliser        = return Exit
  }

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> repl $ return ()
    [fname] -> repl $ load fname
    _ -> putStrLn "invalid args"
