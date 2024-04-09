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
%token Index
%token If Then Else

/* Precedence and associativity specification */
%left       Lambda
%nonassoc   Number Boolean LParens Index
%left       Or
%left       And
%left       Equals LAngle RAngle Neq Geq Leq 
%nonassoc   Not
%left       Plus Minus
%left       Times

/* Starting symbol */

%start program
%type <Ast.exp> program   /* the parser returns a Ast.exp value */
%type <Ast.exp> expr
%type <Ast.aexp> aexpr 
%type <Ast.bexp> bexpr
%type <Ast.exp> lambdaexp
%type <Ast.exp> applyexp
%type <Ast.exp> operandapplyexp
%type <Ast.exp> operandexp

%%

/* Grammar specification */

program:
  | e = expr EOF                                {e}

expr:
  | lambdaexp %prec Lambda                      {$1}
  | operandapplyexp                             {$1}

operandapplyexp:
  | applyexp                                    {$1}
  | operandexp                                  {$1}

operandexp:
  | LParens operandapplyexp RParens             {$2}
  | a = aexpr                                   {Ast.Aexp(a)}
  | b = bexpr                                   {Ast.Bexp(b)}
  | LParens If expr Then expr Else expr RParens {Ast.IfThenElse($3, $5, $7)}

lambdaexp:
  | Lambda e = expr                             {Ast.Lambda(e)}
  | LParens lambdaexp RParens                   {$2}
  | Index n = Number                            {Ast.Var(n)}

applyexp:
  | lambdaexp expr                              {Ast.Apply($1, $2)}

aexpr:
  | n = Number                                  {Ast.IntConst(n)}
  | operandexp abinop operandexp                {Ast.ABinop($2, $1, $3)}
  | LParens aunop operandexp RParens            {Ast.AUnop($2, $3)}

%inline aunop:
  | Minus                                       {Ast.Neg}

%inline abinop:
  | Plus                                        {Ast.Plus}
  | Minus                                       {Ast.Minus}
  | Times                                       {Ast.Times}

bexpr:
  | b = Boolean                                 {Ast.BoolConst(b)}
  | operandexp bbinop operandexp                {Ast.BBinop($2, $1, $3)}
  | operandexp comp operandexp                  {Ast.Compare($2, $1, $3)}
  | bunop operandexp                            {Ast.BUnop($1, $2)}

%inline bunop:
  | Not                                         {Ast.Not}

%inline bbinop:
  | And                                         {Ast.And}
  | Or                                          {Ast.Or}

%inline comp:
  | Equals                                      {Ast.Equals}
  | Neq                                         {Ast.NotEqual}
  | LAngle                                      {Ast.LessThan}
  | RAngle                                      {Ast.GreaterThan}
  | Leq                                         {Ast.LessEqual}
  | Geq                                         {Ast.GreaterEqual}
