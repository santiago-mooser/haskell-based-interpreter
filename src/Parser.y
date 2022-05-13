{
module Parser (parseExpr) where
import Prelude hiding (LT, GT, EQ)
import Common
import Source
import Tokens
}


%name parser
%tokentype { Token }
%error { parseError }

%token
    var     { TokenVar }
    vars    { TokenVars }
    and     { TokenAAnd }
    id      { TokenSym $$ }
    label   { TokenSym $$ }
    int     { TokenInt $$ }
    string  { TokenString $$ }
    '+'     { TokenPlus }
    '-'     { TokenMinus }
    '*'     { TokenTimes }
    '/'     { TokenDiv }
    '('     { TokenLParen }
    ')'     { TokenRParen }
    '}'     { TokenRBrace }
    '{'     { TokenLBrace }
    '['     { TokenLBracket }
    ']'     { TokenRBracket }
    ';'     { TokenSemiColon }
    ':'     { TokenColon }
    ','     { TokenComma }
    '.'     { TokenPeriod }
    '='     { TokenEq }
    ':='    { TokenAssign }
    if      { TokenIf }
    else    { TokenElse }
    true    { TokenTrue }
    false   { TokenFalse }
    '<'     { TokenLT }
    '<='    { TokenLE }
    '>'     { TokenGT }
    '>='    { TokenGE }
    '=='    { TokenComp }
    '&&'    { TokenAnd }
    '||'    { TokenOr }
    '!!'    { TokenIndex }
    '++'    { TokenAppend }
    '\\'    { TokenRemove }
    '#'     { TokenNumber }
    '?'     { TokenQuestion }
    '!'     { TokenNot }
    '=>'    { TokenArrow }
    fun     { TokenFunc }
    clone   { TokenClone }
    class   { TokenClass }
    new     { TokenNew }
    rec     { TokenRec }

%right ';' else
%left '||'
%left '&&'
%nonassoc '=='
%nonassoc '>' '<' '>=' '<='
%left '++' '\\'
%left '+' '-'
%left '*' '/'
%left '!!'
%left NEG '!' '#' '?'

%monad { Either String }


%%

Exp : fun '(' id ')' '{' Exp '}'         { Fun $3 $6 }
    | var id '=' Exp ';' Exp             { Let $2 $4 $6 }
    | var rec id '=' Exp ';' Exp         { Letrec $3 $5 $7 }
    | if '(' Exp ')' Exp ';' else Exp    { If $3 $5 $8 }
    | class '{' Methods '}'              { Class $3 }
    | new Exp                            { New $2 }
    | Oper                               { $1 }

Oper : Oper '!!' Oper                    { Binary Index $1 $3 }
     | Oper '++' Oper                    { Binary Append $1 $3 }
     | Oper '\\' Oper                    { Binary Remove $1 $3 }
     | Oper '||' Oper                    { Binary Or $1 $3 }
     | Oper '&&' Oper                    { Binary And $1 $3 }
     | Oper '==' Oper                    { Binary EQ $1 $3 }
     | Oper '<' Oper                     { Binary LT $1 $3 }
     | Oper '>' Oper                     { Binary GT $1 $3 }
     | Oper '<=' Oper                    { Binary LE $1 $3 }
     | Oper '>=' Oper                    { Binary GE $1 $3 }
     | Oper '+' Oper                     { Binary Add $1 $3 }
     | Oper '-' Oper                     { Binary Sub $1 $3 }
     | Oper '*' Oper                     { Binary Mult $1 $3 }
     | Oper '/' Oper                     { Binary Div $1 $3 }
     | '-' Oper %prec NEG                { Unary Neg $2 }
     | '!' Oper                          { Unary Not $2 }
     | '#' Oper                          { Unary Length $2 }
     | '?' Oper                          { Unary Null $2 }
     | App '.' id ':=' Method            { Update $1 $3 $5 }
     | App                               { $1 }

App : App '(' Exp ')'                    { Call $1 $3 }
    | App '.' id                         { Invoke $1 $3 }
    | '{' Methods '}'                    { Object $2 }
    | clone '(' Exp ')'                  { Clone $3 }
    | '[' Elements ']'                   { Array $2 }
    | id                                 { Var $1 }
    | int                                { Lit (IntV $1) }
    | string                             { Lit (StringV $1) }
    | true                               { Lit (BoolV True) }
    | false                              { Lit (BoolV False) }
    | '(' Exp ')'                        { $2 }

Methods : id ':' Method ',' Methods      { ($1, $3) : $5 }
        | id ':' Method                  { [($1, $3)] }

Method : id '=>' Exp                     { Method $1 $3 }
       | Exp                             { Method "_" $1 }

Elements : Exp ',' Elements              { $1 : $3 }
         | Exp                           { [$1] }

{

parseError _ = Left "Parse error"

parseExpr = parser . scanTokens

}
