type aunop = Neg

type abinop = Plus

type bunop = Not
type bbinop = And | Or
type comparator = Equals | LessThan

(* Syntax of the language *)
type aexp =
  | ABinop of abinop * exp * exp
  | AUnop of aunop * exp
and bexp =
  | BBinop of bbinop * exp * exp
  | BUnop  of bunop * exp
  | Compare of comparator * exp * exp
and exp =
  | Lambda      : exp
  | Apply       : exp * exp
  | IfThenElse  : exp * exp * exp
  | Aexp        : aexp
  | Bexp        : bexp
  | Var         : nat
  | Val         : value
with value =
  | Closure     : environment * exp
  | BoolConst   : bool
  | IntConst    : Z
with environment = Empty | Env of (value * environment)





