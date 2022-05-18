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
    Sigma.Var y                             -> if arg == y then Sigma.Invoke xself "arg" else Sigma.Var y
    Sigma.Object mlist                      -> Sigma.Object [(l, Sigma.Method l (replace m arg xself)) | (l, Sigma.Method ml m) <- mlist]
    Sigma.Invoke t l                        -> Sigma.Invoke (replace t arg xself) l
    Sigma.Update t l (Sigma.Method ml m)    -> Sigma.Update (replace t arg xself) l (Sigma.Method ml (replace m arg xself))
    Sigma.Clone t                           -> Sigma.Clone (replace t arg xself)
    Sigma.Lit l                             -> Sigma.Lit l
    Sigma.Unary op t                        -> Sigma.Unary op (replace t arg xself)
    Sigma.Binary op t1 t2                   -> Sigma.Binary op (replace t1 arg xself) (replace t2 arg xself)
    Sigma.If t1 t2 t3                       -> Sigma.If (replace t1 arg xself) (replace t2 arg xself) (replace t3 arg xself)
    Sigma.Let x t1 t2                       -> Sigma.Let x (replace t1 arg xself) (replace t2 arg xself)


translate :: Source.Exp -> Sigma.Term
translate (Source.Var x) = Sigma.Var x
translate (Source.Object mlist) = Sigma.Object [(l, Sigma.Method ml (translate m)) | (l, Source.Method ml m) <- mlist]
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
        xself           = Sigma.Var "self"
        replaced_bod    = replace bod arg xself
    in Sigma.Object [
            ("arg", Sigma.Method "self" (Sigma.Invoke xself "arg")),
            ("val", Sigma.Method "self" replaced_bod)
        ]
translate (Source.Call func exp) =
    let f = Sigma.Clone (translate func)
        e = Sigma.Method "exp" (translate exp)
    in Sigma.Invoke (Sigma.Update f "arg" e) "val"

translate (Source.Class mlist) =
    let translated_methods = [(l, Sigma.Method ml (translate m)) | (l, Source.Method ml m) <- mlist]
        new_method = [("new", Sigma.Method "z" (Sigma.Object translated_methods))]
    in Sigma.Object new_method
translate (Source.New obj) =
    Sigma.Invoke (translate obj) "new"

translate Source.Letrec {} = error "translate: letrec"
translate (Source.Array _) = error "translate: array"
--encode a function using an object with two methods. The first method (arg) stores the argument.
-- In the second method (val), body is first recursively translated (denoted by |body|), and then all the occurrences of x are substituted by self.arg in the translated body
-- translate (Source.Fun var exp) =

-- translate (Source.Call exp exp) =S