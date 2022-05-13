{
module Tokens where
}

%wrapper "basic"

$digit = 0-9
$alpha = [a-zA-Z]

tokens :-

  $white+                       ;
  "--".*                        ;
  var                           { \s -> TokenVar }
  vars                          { \s -> TokenVars }
  and                           { \s -> TokenAAnd }
  if                            { \s -> TokenIf }
  else                          { \s -> TokenElse }
  true                          { \s -> TokenTrue }
  false                         { \s -> TokenFalse }
  $digit+                       { \s -> TokenInt (read s) }
  \"[^\"]*\"                    { \s -> TokenString (tail (init s)) }
  \;                            { \s -> TokenSemiColon }
  \=                            { \s -> TokenEq }
  \+                            { \s -> TokenPlus }
  \-                            { \s -> TokenMinus }
  \*                            { \s -> TokenTimes }
  \/                            { \s -> TokenDiv }
  \^                            { \s -> TokenPow }
  \<                            { \s -> TokenLT }
  \<\=                          { \s -> TokenLE }
  \>\=                          { \s -> TokenGE }
  \>                            { \s -> TokenGT }
  \=\=                          { \s -> TokenComp }
  \&\&                          { \s -> TokenAnd }
  \|\|                          { \s -> TokenOr }
  \!\!                          { \s -> TokenIndex }
  \+\+                          { \s -> TokenAppend }
  \\\\                          { \s -> TokenRemove }
  \#                            { \s -> TokenNumber }
  \?                            { \s -> TokenQuestion }
  \!                            { \s -> TokenNot }
  \(                            { \s -> TokenLParen }
  \)                            { \s -> TokenRParen }
  \{                            { \s -> TokenLBrace }
  \}                            { \s -> TokenRBrace }
  \[                            { \s -> TokenLBracket }
  \]                            { \s -> TokenRBracket }
  \,                            { \s -> TokenComma }
  \:                            { \s -> TokenColon }
  \.                            { \s -> TokenPeriod }
  \:\=                          { \s -> TokenAssign }
  \=\>                          { \s -> TokenArrow }
  clone                         { \s -> TokenClone }
  class                         { \s -> TokenClass }
  new                           { \s -> TokenNew }
  function                      { \s -> TokenFunc }
  rec                           { \s -> TokenRec }
  $alpha [$alpha $digit \_ \']* { \s -> TokenSym s }



{
data Token = TokenInt Int
           | TokenString String
           | TokenSym String
           | TokenVar
           | TokenVars
           | TokenAAnd
           | TokenIf
           | TokenElse
           | TokenTrue
           | TokenFalse
           | TokenSemiColon
           | TokenEq
           | TokenPlus
           | TokenMinus
           | TokenTimes
           | TokenDiv
           | TokenPow
           | TokenLT
           | TokenLE
           | TokenGT
           | TokenGE
           | TokenComp
           | TokenAnd
           | TokenOr
           | TokenIndex
           | TokenAppend
           | TokenRemove
           | TokenNumber
           | TokenQuestion
           | TokenNot
           | TokenLParen
           | TokenRParen
           | TokenLBrace
           | TokenRBrace
           | TokenLBracket
           | TokenRBracket
           | TokenComma
           | TokenColon
           | TokenPeriod
           | TokenAssign
           | TokenArrow
           | TokenClone
           | TokenClass
           | TokenNew
           | TokenFunc
           | TokenRec
           deriving (Eq, Show)

scanTokens = alexScanTokens
}
