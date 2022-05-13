module Common where

import Prelude hiding (LT, GT, EQ)

type Label = String
type Var = String

data BinaryOp = Add | Sub | Mult | Div | And | Or
              | GT  | LT  | LE   | GE  | EQ
              | Index | Append | Remove
              deriving Eq

instance Show BinaryOp where
  show Add    = "+"
  show Sub    = "-"
  show Mult   = "*"
  show Div    = "/"
  show And    = "&&"
  show Or     = "||"
  show GT     = ">"
  show LT     = "<"
  show LE     = "<="
  show GE     = ">="
  show EQ     = "=="
  show Index  = "!!"
  show Append = "++"
  show Remove = "\\\\"

data UnaryOp = Neg | Not | Length | Null
             deriving Eq

instance Show UnaryOp where
  show Neg    = "-"
  show Not    = "!"
  show Length = "#"
  show Null   = "?"

showMethod :: Show m => (Label, m) -> String
showMethod (l, m) = show l ++ ": " ++ show m

data Value = IntV Int
           | BoolV Bool
           | StringV String
           | ObjRef Int
           deriving Eq

instance Show Value where
  show (IntV i)    = show i
  show (BoolV b)   = show b
  show (StringV s) = show s
  show (ObjRef i)  = "@" ++ show i

unary :: UnaryOp -> Value -> Value
unary Not (BoolV b) = BoolV (not b)
unary Neg (IntV i)  = IntV (-i)
unary Length (StringV s) = IntV (length s)
unary Null (StringV s) = BoolV (s == "")
unary _ _ = error "Invalid unary operation"

binary :: BinaryOp -> Value -> Value -> Value
binary Add    (IntV a)      (IntV b)    = IntV (a + b)
binary Sub    (IntV a)      (IntV b)    = IntV (a - b)
binary Mult   (IntV a)      (IntV b)    = IntV (a * b)
binary Div    (IntV a)      (IntV b)    = IntV (a `div` b)
binary And    (BoolV a)     (BoolV b)   = BoolV (a && b)
binary Or     (BoolV a)     (BoolV b)   = BoolV (a || b)
binary LT     (IntV a)      (IntV b)    = BoolV (a < b)
binary LE     (IntV a)      (IntV b)    = BoolV (a <= b)
binary GE     (IntV a)      (IntV b)    = BoolV (a >= b)
binary GT     (IntV a)      (IntV b)    = BoolV (a > b)
binary EQ     a             b           = BoolV (a == b)
binary Index  (StringV s1) (IntV i)     = StringV [s1 !! i]
binary Append (StringV s1) (StringV s2) = StringV (s1 ++ s2)
binary Remove (StringV s1) (StringV s2) = StringV [ x | x <- s1, x `notElem` s2 ]
binary _ _ _ = error "Invalid binary operation"