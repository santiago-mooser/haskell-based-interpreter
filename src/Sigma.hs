module Sigma where

import Common (Label, Var, Value, UnaryOp (..), BinaryOp (..), showMethod)
import Data.List (intercalate)
import Prelude hiding (LT, GT, EQ)

data Term = Var Var                     -- x, y, ...
          | Object [(Label, Method)]    --{ l: self \=> 0 }
          | Invoke Term Label           -- x.l
          | Update Term Label Method    -- x.l := self \=> 0
          | Clone Term
          | Lit Value                   -- 0, 1, ..., true, false
          | Unary UnaryOp Term          -- -10, !false
          | Binary BinaryOp Term Term   -- 4+8, true||false
          | If Term Term Term           -- if (x < 0) -1; else 1
          | Let Var Term Term           -- var x = 1; x + 2
          deriving Eq

instance Show Term where
  show (Var x) = x
  show (Object ms) = "{ " ++ intercalate ", " (map showMethod ms) ++ " }"
  show (Invoke a l) = show a ++ "." ++ l
  show (Update a l m) = show a ++ "." ++ l ++ " := " ++ show m
  show (Clone a) = "clone(" ++ show a ++ ")"
  show (Lit v) = show v
  show (Unary op a) =  show op ++ show a
  show (Binary op a b) = "(" ++ show a ++ " " ++ show op ++ " " ++ show b ++ ")"
  show (If a b c) = "if (" ++ show a ++ ") " ++ show b ++ "; else " ++ show c
  show (Let x a b) = "var " ++ x ++ " = " ++ show a ++ "; " ++ show b

data Method = Method Var Term deriving Eq

instance Show Method where
  show (Method s t) = s ++ " => " ++ show t