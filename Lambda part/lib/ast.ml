type aunop = Neg
type abinop = Plus

type bunop = Not
type bbinop = And | Or
type comparator = Equals | LessThan

(* Syntax of the language *)
type aexp =
  | ABinop      of abinop * aexp * aexp
  | AUnop       of aunop * aexp
  | IntConst    of int
and bexp =
  | BBinop      of bbinop * bexp * bexp
  | BUnop       of bunop * bexp
  | Compare     of comparator * aexp * aexp
  | BoolConst   of bool
and exp =
  | Lambda      of exp
  | Apply       of exp * exp
  | IfThenElse  of exp * exp * exp
  | Aexp        of aexp
  | Bexp        of bexp
  | Var         of int