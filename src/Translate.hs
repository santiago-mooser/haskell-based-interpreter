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
    Sigma.Object mlist                      -> Sigma.Object(helper_replace arg xself mlist)
                                                where
                                                    helper_replace :: Common.Var-> Sigma.Term -> [(Common.Label, Sigma.Method)] -> [(Common.Label, Sigma.Method)]
                                                    helper_replace arg xself [] = []
                                                    helper_replace arg xself (x:xs) = case x of
                                                        (l, Sigma.Method ml term) ->
                                                            if arg == ml then x:helper_replace arg xself xs
                                                            else (l, Sigma.Method ml (replace term arg xself)):helper_replace arg xself xs
    Sigma.Invoke t l                        -> Sigma.Invoke (replace t arg xself) l
    Sigma.Update t l (Sigma.Method ml m)    ->  if arg == ml then Sigma.Update t l (Sigma.Method ml m)
                                                else Sigma.Update t l (Sigma.Method ml (replace m arg xself))
    Sigma.Clone t                           -> Sigma.Clone (replace t arg xself)
    Sigma.Lit l                             -> Sigma.Lit l
    Sigma.Unary op t                        -> Sigma.Unary op (replace t arg xself)
    Sigma.Binary op t1 t2                   -> Sigma.Binary op (replace t1 arg xself) (replace t2 arg xself)
    Sigma.If t1 t2 t3                       -> Sigma.If (replace t1 arg xself) (replace t2 arg xself) (replace t3 arg xself)
    Sigma.Let x t1 t2                       ->  if arg == x then Sigma.Let x (replace t1 arg xself) t2
                                                else Sigma.Let x (replace t1 arg xself) (replace t2 arg xself)


fixFunction :: Source.Exp
fixFunction =
    let invocation = Source.Call (Source.Var "f") (Source.Invoke (Source.Var "self") "rec")
        method = Source.Method "self" invocation
        object = Source.Object [("rec", method)]
    in
    Source.Fun "f" (Source.Invoke object "rec")

desugar :: Common.Var -> Source.Exp -> Source.Exp
desugar var exp = Source.Call fixFunction (Source.Fun var exp)

translate :: Source.Exp -> Sigma.Term
translate (Source.Var x)                                    = Sigma.Var x
translate (Source.Object mlist)                             = Sigma.Object [(l, Sigma.Method ml (translate m)) | (l, Source.Method ml m) <- mlist]
translate (Source.Invoke exp label)                         = Sigma.Invoke (translate exp) label
translate (Source.Update exp1 label (Source.Method v exp2)) = Sigma.Update (translate exp1) label (Sigma.Method v (translate exp2))
translate (Source.Clone exp)                                = Sigma.Clone (translate exp)
translate (Source.Lit val)                                  = Sigma.Lit val
translate (Source.Unary op exp)                             = Sigma.Unary op (translate exp)
translate (Source.Binary op exp1 exp2)                      = Sigma.Binary op (translate exp1) (translate exp2)
translate (Source.If exp1 exp2 exp3)                        = Sigma.If (translate exp1) (translate exp2) (translate exp3)
translate (Source.Let var exp1 exp2)                        = Sigma.Let var (translate exp1) (translate exp2)
translate (Source.Fun arg body)                             =   let bod             = translate body                            --  Translate the body first
                                                                    xself           = Sigma.Var arg                             -- Then build a variable for the self argument
                                                                    replaced_bod    = replace bod arg xself                     -- Finally replace all occurences of the self argument with the variable
                                                                in Sigma.Object [                                               -- Then build the object
                                                                        ("arg", Sigma.Method arg (Sigma.Invoke xself "arg")),
                                                                        ("val", Sigma.Method arg replaced_bod)
                                                                    ]

translate (Source.Call func exp)                            =   let f = Sigma.Clone (translate func)                  -- Clone the function
                                                                    e = Sigma.Method "exp" (translate exp)            -- Build the method for the argument
                                                                in Sigma.Invoke (Sigma.Update f "arg" e) "val"        -- Invoke the function with the argument

translate (Source.Class mlist)                              =   let translated_methods = [(l, Sigma.Method ml (translate m)) | (l, Source.Method ml m) <- mlist]    -- Translate the methods using a map
                                                                    new_method = [("new", Sigma.Method "z" (Sigma.Object translated_methods))]                      -- Build the new method
                                                                in Sigma.Object new_method                                                                          -- Build the object

translate (Source.New obj)                                  = Sigma.Invoke (translate obj) "new"
translate (Source.Letrec var exp1 exp2)                     = translate (Source.Let var (desugar var exp1) exp2)

translate (Source.Array arr)                                = Sigma.Object (translate_helper_2 arr 0)
    where
    translate_helper_2 :: [Source.Exp] -> Integer-> [(Common.Label, Sigma.Method)]
    translate_helper_2 [] _ = []
    translate_helper_2 (x:xs) label = (show label, Sigma.Method (show label) (translate x)):translate_helper_2 xs (label+1)