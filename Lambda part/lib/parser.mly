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
%token Apply
%token Ycomb
%token HOApply
%token FIndex

/* Precedence and associativity specification */
%nonassoc   Else
%left       And Or
%left       Equals LAngle RAngle Leq Neq Geq
%right      Not Minus
%left       Plus Times
%right      Lambda

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
  | Lambda e = expr                                 {Ast.Lambda(e)}
  | LParens e = expr RParens                        {e}
  | Apply LParens e1 = expr RParens LParens e2 = expr RParens      {Ast.Apply(e1, e2)}
  | HOApply LParens e1 = expr RParens LParens e2 = expr RParens      {Ast.HOApply(e1, e2)}
  | LIndex n = Number                               {Ast.Var(n)}
  | FIndex n = Number                               {Ast.HOVar(n)}
  | GIndex n = Number                               {Ast.Var(-n)}
  | a = aexpr                                       {Ast.Aexp(a)}
  | b = bexpr                                       {Ast.Bexp(b)}
  | If e1 = expr Then e2 = expr Else e3 = expr      {Ast.IfThenElse(e1, e2, e3)}
  | Ycomb                                           {(Ast.Lambda
                                                        (Ast.Apply (
                                                            (Ast.Lambda
                                                              (Ast.Apply ((Ast.Var 1),
                                                                  (Ast.Lambda
                                                                    (Ast.Apply ((Ast.Apply ((Ast.Var 1), (Ast.Var 1))),
                                                                        (Ast.Var 0))))
                                                                  ))),
                                                            (Ast.Lambda
                                                              (Ast.Apply ((Ast.Var 1),
                                                                  (Ast.Lambda
                                                                    (Ast.Apply ((Ast.Apply ((Ast.Var 1), (Ast.Var 1))),
                                                                        (Ast.Var 0))))
                                                                  )))
                                                            )))
                                                      }
  
aexpr:
  | n = Number                                      {Ast.IntConst(n)}
  | e1 = expr op = abinop e2 = expr                 {Ast.ABinop(op, e1, e2)}
  | op = aunop e = expr                             {Ast.AUnop(op, e)}

%inline aunop:
  | Minus                                           {Ast.Neg}

%inline abinop:
  | Plus                                            {Ast.Plus}
  | Minus                                           {Ast.Minus}
  | Times                                           {Ast.Times}

bexpr:
  | b = Boolean                                     {Ast.BoolConst(b)}
  | e1 = expr op = bbinop e2 = expr                 {Ast.BBinop(op, e1, e2)}
  | e1 = expr op = comp e2 = expr                   {Ast.Compare(op, e1, e2)}
  | op = bunop e = expr                             {Ast.BUnop(op, e)}

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
