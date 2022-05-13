module Source where

import Common (Label, Var, Value, UnaryOp, BinaryOp, showMethod)
import Data.List (intercalate)

data Exp = Var Var
         | Object [(Label, Method)]
         | Invoke Exp Label
         | Update Exp Label Method
         | Clone Exp
         | Lit Value
         | Unary UnaryOp Exp
         | Binary BinaryOp Exp Exp
         | If Exp Exp Exp
         | Let Var Exp Exp
         | Fun Var Exp              -- new!
         | Call Exp Exp             -- new!
         | Class [(Label, Method)]  -- new!
         | New Exp                  -- new!
         | Letrec Var Exp Exp       -- new!
         | Array [Exp]              -- new!
         deriving Eq

instance Show Exp where
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
  show (Fun x a) = "function(" ++ show x ++ ") { " ++ show a ++ " }"
  show (Call a b) = show a ++ "(" ++ show b ++ ")"
  show (Class ms) = "class { " ++ intercalate "," (map showMethod ms) ++ " }"
  show (New a) = "(new " ++ show a ++ ")"
  show (Letrec x a b) = "var rec " ++ x ++ " = " ++ show a ++ "; " ++ show b
  show (Array as) = "[" ++ intercalate "," (map show as) ++ "]"

data Method = Method Var Exp deriving Eq

instance Show Method where
  show (Method "_" a) = show a
  show (Method v a) =  "{" ++ v ++ "} " ++ show a
