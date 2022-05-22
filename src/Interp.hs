module Interp where

import Data.Maybe (fromJust)
import Common (Label, Var, Value(..), binary, unary)
import Sigma (Method(..), Term(..))

data MethodClosure = Closure Env Var Term
type Obj = [(Label, MethodClosure)]
type Mem = [Obj]

replace :: Int -> Label -> MethodClosure -> Mem -> Mem
replace i l closure mem =
  let (before, o : after) = splitAt i mem in
  before ++ [[if l == n then (n, closure) else (n, c) | (n, c) <- o]] ++ after

type Env = [(Var, Value)]

evaluate :: Term -> Env -> Mem -> Maybe (Value, Mem)
evaluate (Var x) env mem =
  case lookup x env of
    Just a -> Just (a, mem)
    Nothing -> error ("No such variable " ++ show x)
evaluate (Object ms) env mem =
  let m2mc (l, Method self term) = (l, Closure env self term) in
  Just (ObjRef (length mem), mem ++ [map m2mc ms])
evaluate (Invoke a l) env mem =
  case evaluate a env mem of
    Just (ObjRef i, mem') ->
      let ms = mem' !! i in
      case lookup l ms of
        Just (Closure env self term) -> evaluate term ((self, ObjRef i) : env) mem'
        _ -> error ("Object " ++ show i ++ " has no method " ++ show l)
    _ -> error ("Cannot invoke non-object " ++ show a)
evaluate (Update a l (Method self term)) env mem =
  case evaluate a env mem of
    Just (ObjRef i, mem') ->
      Just (ObjRef i, replace i l (Closure env self term) mem')
    _ -> error ("Cannot update non-object " ++ show a)
evaluate (Lit v) env mem = Just (v, mem)
evaluate (Unary op a) env mem =
  case evaluate a env mem of
    Just (a', mem') -> Just (unary op a', mem')
    Nothing -> error ("Cannot apply unary operator " ++ show op ++ " to non-value " ++ show a)
evaluate (Binary op a b) env mem =
  case evaluate a env mem of
    Just (a', mem') -> case evaluate b env mem' of
      Just (b', mem'') -> Just (binary op a' b', mem'')
      Nothing -> error ("Cannot apply binary operator " ++ show op ++ " to non-value " ++ show b)
    Nothing -> error ("Cannot apply binary operator " ++ show op ++ " to non-value " ++ show a)
evaluate (If a b c) env mem =
  case evaluate a env mem of
    Just (BoolV True, mem') -> evaluate b env mem'
    Just (BoolV False, mem') -> evaluate c env mem'
    _ -> error ("Condition in if statement returned a non-Boolean value: " ++ show a)
evaluate (Let x a b) env mem =
  case evaluate a env mem of
    Just (a', mem') -> evaluate b ((x, a') : env) mem'
    Nothing -> error ("Cannot bind non-value " ++ show a ++ " to variable " ++ show x)
evaluate (Clone a) env mem =
  case evaluate a env mem of
    Just (ObjRef i, mem') ->
      let mcs = mem' !! i in
        Just (ObjRef (length mem'), mem' ++ [mcs])
    Just (a', mem') -> error ("Unable to clone " ++ show a ++ ". Not an Object")
    Nothing -> error ("Unable to clone non-object " ++ show a)

execute :: Term -> Value
execute e = fst $ fromJust $ evaluate e [] []
