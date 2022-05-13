{-# OPTIONS_GHC -Wno-incomplete-patterns #-}
module Translate where

import qualified Source
import qualified Sigma
import GHC.RTS.Flags (TraceFlags(traceScheduler))
import qualified Text.Read as Sigma

translate :: Source.Exp -> Sigma.Term
translate (Source.Var x) = Sigma.Var x
translate (Source.Object [(label, Source.Method v e )]) = Sigma.Object [(label, Sigma.Method v (translate e))]
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
    in Sigma.Object [
            ("arg", Sigma.Method "arg" (Sigma.Var "self")),
            ("val", Sigma.Method "val" bod)
        ]


    -- let bod = translate body

    -- in Sigma.Object [   ("arg", Sigma.Method "arg" (Sigma.Var arg)),
    --                     ("val", Sigma.Method "val" bod)
                    -- ]
translate (Source.Call func exp) =
    -- turn into: var f = clone(|fun|); var e = |exp|; (f.arg := e).val
    let f = Sigma.Clone (translate func)
        e = Sigma.Method "exp" (translate exp)
    in Sigma.Invoke (Sigma.Update f "arg" e) "val"

--encode a function using an object with two methods. The first method (arg) stores the argument.
-- In the second method (val), body is first recursively trans-lated (denoted by |body|), and then all the occurrences of x are substituted by self.arg in the translated body
-- translate (Source.Fun var exp) =

-- translate (Source.Call exp exp) =S