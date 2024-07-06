type aunop = Neg
[@@deriving show]
type abinop = Plus | Minus | Times
[@@deriving show]

type bunop = Not
[@@deriving show]
type bbinop = And | Or
[@@deriving show]
type comparator = Equals | LessThan | GreaterThan | LessEqual | GreaterEqual | NotEqual
[@@deriving show]

(* Syntax of the language *)
type aexp =
  | ABinop      of abinop * exp * exp
  | AUnop       of aunop * exp
  | IntConst    of int
  [@@deriving show]
and bexp =
  | BBinop      of bbinop * exp * exp
  | BUnop       of bunop * exp
  | Compare     of comparator * exp * exp
  | BoolConst   of bool
  [@@deriving show]
and exp =
  | Lambda      of exp
  | Apply       of exp * exp
  | HOApply     of exp * exp
  | IfThenElse  of exp * exp * exp
  | Aexp        of aexp
  | Bexp        of bexp
  | Var         of int
  | Interrupt   of int * exp * exp * exp * exp * exp * exp * exp * exp * exp  (* 1 for number of interrupt, 8 for registers, final is callback *)
  [@@deriving show]
