/*
* Lambda Parser specification
*/

%{
     (* Auxiliary definitions *)
%}

/* Tokens declarations */
%token EOF
%token Lambda
%token <int> Number
%token Plus Minus Times
%token <bool> Boolean
%token Not And Or
%token Equals LAngle RAngle Neq Geq Leq
%token LParens RParens
%token LIndex GIndex
%token If Then Else

/* Precedence and associativity specification */
// %nonassoc   Else
%left       Or
%left       And
%left       Equals LAngle RAngle Leq Neq Geq
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
  | LParens Lambda e = expr RParens             {Ast.Lambda(e)}
  | LParens expr RParens            {$2}
  | LParens expr expr RParens                       {Ast.Apply($2, $3)}
  | LIndex n = Number                {Ast.Var(n)}
  | GIndex n = Number                {Ast.Var(-n)}
  | aexpr                           {Ast.Aexp($1)}
  | bexpr                           {Ast.Bexp($1)}
  | LParens If expr Then expr Else expr RParens     {Ast.IfThenElse($3, $5, $7)}

aexpr:
  | n = Number                      {Ast.IntConst(n)}
  | expr abinop expr                {Ast.ABinop($2, $1, $3)}
  | LParens aunop expr RParens                      {Ast.AUnop($2, $3)}

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
  | Neq                             {Ast.NotEqual}
  | LAngle                          {Ast.LessThan}
  | RAngle                          {Ast.GreaterThan}
  | Leq                             {Ast.LessEqual}
  | Geq                             {Ast.GreaterEqual}
