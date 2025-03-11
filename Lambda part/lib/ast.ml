type aunop = Neg
[@@deriving show]
type abinop = Plus | Times | Div
[@@deriving show]

type bigbinop = BigPlus
[@@deriving show]

type bigunop = BigNeg
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
and bigexp = 
  | BigInt      of int    (*Maybe use strings or ocaml bigints to initialize bigger ints*)
  | BigBinop    of bigbinop * exp * exp
  | BigUnop     of bigunop * exp
  [@@deriving show]
and exp =
  | Lambda      of exp
  | Lambdas     of int * exp
  | Apply       of exp * exp
  | MultiApply  of exp * exp list
  | HOApply     of exp * exp
  | IfThenElse  of exp * exp * exp
  | Aexp        of aexp
  | Bexp        of bexp
  | Bigexp      of bigexp
  | Var         of int
  | Interrupt   of exp  (* function representing tuple: 1 for number of interrupt, 8 for registers, final is callback *)
  | Switch      of exp list * int
  | Die
  | SayHere     of exp
  [@@deriving show]
