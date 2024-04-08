/*
* Lambda Parser specification
*/

%{
     (* Auxiliary definitions *)
%}

/* Tokens declarations */
%token EOF
%token Lambda
%token Dot
%token <int> Number
%token Plus Minus Times
%token <bool> Boolean
%token Not And Or
%token Equals LAngle RAngle
%token LParens RParens
%token Index
%token If Then Else

/* Precedence and associativity specification */
%nonassoc   Dot Else
%left       Or
%left       And
%left       Equals
%left       LAngle RAngle
%nonassoc   Not
%left       Plus Minus
%left       Times

/* Starting symbol */

%start program
%type <Ast.exp> program   /* the parser returns a Ast.exp value */
%type <Ast.exp> expr
%type <Ast.aexp> aexpr 
%type <Ast.bexp> bexpr

%%

/* Grammar specification */

program:
  | e = expr EOF                    {e}

expr:
  | Lambda Dot e = expr             {Ast.Lambda(e)}
  | LParens expr RParens            {$2}
  | expr expr                       {Ast.Apply($1, $2)}
  | Index n = Number                {Ast.Var(n)}
  | aexpr                           {Ast.Aexp($1)}
  | bexpr                           {Ast.Bexp($1)}
  | If expr Then expr Else expr     {Ast.IfThenElse($2, $4, $6)}

aexpr:
  | n = Number                      {Ast.IntConst(n)}
  | expr abinop expr                {Ast.ABinop($2, $1, $3)}
  | aunop expr                      {Ast.AUnop($1, $2)}

%inline aunop:
  | Minus                           {Ast.Neg}

%inline abinop:
  | Plus                            {Ast.Plus}
  | Minus                           {Ast.Minus}
  | Times                           {Ast.Times}

bexpr:
  | b = Boolean                     {Ast.BoolConst(b)}
  | expr bbinop expr                {Ast.BBinop($2, $1, $3)}
  | expr comp expr                  {Ast.Compare($2, $1, $3)}
  | bunop expr                      {Ast.BUnop($1, $2)}

%inline bunop:
  | Not                             {Ast.Not}

%inline bbinop:
  | And                             {Ast.And}
  | Or                              {Ast.Or}

%inline comp:
  | Equals                          {Ast.Equals}
  | Not Equals                      {Ast.NotEqual}
  | LAngle                          {Ast.LessThan}
  | RAngle                          {Ast.GreaterThan}
  | LAngle Equals                   {Ast.LessEqual}
  | RAngle Equals                   {Ast.GreaterEqual}
