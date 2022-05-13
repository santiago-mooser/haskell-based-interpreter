{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use camelCase" #-}


module Translate where

import qualified Source
import qualified Sigma
import GHC.RTS.Flags (TraceFlags(traceScheduler))
import qualified Text.Read as Sigma
import qualified Common
import qualified Control.Arrow as Data.Bifunctor

-- replace all occurences of x in body with var
replace :: Sigma.Term -> Common.Var -> Sigma.Term -> Sigma.Term
replace bod arg xself = case bod of
    Sigma.Var y -> if arg == y then xself else Sigma.Var y
    a -> a


translate :: Source.Exp -> Sigma.Term
translate (Source.Var x) = Sigma.Var x

-- This is awefully convoluted but it's the only way I got it to work lmao
translate (Source.Object mlist) =
    -- Definte a mapping that takes a list of methods and applies translate to each
    let t_body = map (\(l, Source.Method ml v) -> (l, Sigma.Method ml (translate v))) in --
    case mlist of
        -- If the list of methods is empty, just return an object with no methods (why? lol)
        [] -> Sigma.Object []
        -- Otherwise translate all the methods and then return an object with the translated methods
        (l, Source.Method ml v):xs -> Sigma.Object ((l, Sigma.Method ml (translate v)):t_body xs)
translate (Source.Invoke exp label) = Sigma.Invoke (translate exp) label
translate (Source.Update exp1 label (Source.Method v exp2)) = Sigma.Update (translate exp1) label (Sigma.Method v (translate exp2))
translate (Source.Clone exp) = Sigma.Clone (translate exp)
translate (Source.Lit val) = Sigma.Lit val
translate (Source.Unary op exp) = Sigma.Unary op (translate exp)
translate (Source.Binary op exp1 exp2) = Sigma.Binary op (translate exp1) (translate exp2)
translate (Source.If exp1 exp2 exp3) = Sigma.If (translate exp1) (translate exp2) (translate exp3)
translate (Source.Let var exp1 exp2) = Sigma.Let var (translate exp1) (translate exp2)
translate (Source.Fun arg body) =
    let bod             = translate body
        xself           = Sigma.Var "xself"
        replaced_bod    = replace bod arg xself
    in Sigma.Object [
            ("arg", Sigma.Method "xself" xself),
            ("val", Sigma.Method "xself" replaced_bod)
        ]
translate (Source.Call func exp) =
    let f = Sigma.Clone (translate func)
        e = Sigma.Method "exp" (translate exp)
    in Sigma.Invoke (Sigma.Update f "arg" e) "val"
translate (Source.Class _) = error "translate: class"
translate (Source.New _) = error "translate: new"
translate Source.Letrec {} = error "translate: letrec"
translate (Source.Array _) = error "translate: array"
--encode a function using an object with two methods. The first method (arg) stores the argument.
-- In the second method (val), body is first recursively trans-lated (denoted by |body|), and then all the occurrences of x are substituted by self.arg in the translated body
-- translate (Source.Fun var exp) =

-- translate (Source.Call exp exp) =S