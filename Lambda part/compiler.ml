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
  | Lambda      of exp
  | Apply       of exp * exp
  | IfThenElse  of exp * exp * exp
  | Aexp        of aexp
  | Bexp        of bexp
  | Var         of int
  | Val         of value
and value =
  | Closure     of exp
  | BoolConst   of bool
  | IntConst    of int



let function_counter = ref 0

let fresh_name () =
  function_counter := !function_counter + 1;
  "fun_" ^ string_of_int !function_counter
  
(* returns a pair of strings (s1, s2) where s1 is the code of the main expression, and s2 is the code of the generated functions *)

let rec compile e = (match e with 
  | Val v -> (match v with
      (* closures are compiled by writing (name: body ; ret)  to the function zone, and pushing the address to the operand stack*)
      | Closure e1   ->  let c = compile(e1) in let funname = fresh_name() in ("push_operand "^funname^"\n", funname ^":\n"^ (fst c) ^ "ret\n"^ (snd c))
      | BoolConst b -> ("push_operand " ^ (if b then "1" else "0") ^ "\n", "")
      | IntConst i  -> ("push_operand " ^ (string_of_int i) ^ "\n", "")
    )
  (* gets operand from the environment stack, and pushes it to the operand stack *)
  | Var i -> ("push_operand [ENVIRONMENT_POINTER - " ^ string_of_int ((i + 1) * 2) ^ "]\n", "")
  
  (* in order to apply e1 to e2, first compile them, then pop the operands and call the retrieved function *)
  (* add any functions created by e1 and e2 to the function zone *)
  | Apply (e1, e2) -> let c1 = compile(e1) in let c2 = compile(e2) in
      ((fst c1) ^ (fst c2) ^ "pop_operand ax\npush_env ax\npop_operand ax\ncall ax\n", (snd c1) ^ (snd c2))
  
  | Aexp a -> (match a with 
    | ABinop (o, e1, e2) -> (match o with
      | Plus -> let c1 = compile(e1) in let c2 = compile(e2) in
      ((fst c1) ^ (fst c2) ^ "pop_operand ax\npop_operand bx\nadd ax, bx\npush_operand ax\n", (snd c1) ^ (snd c2))
    )
    | AUnop (o, e1) -> (match o with
      | Neg -> let c1 = compile(e1) in
      ((fst c1) ^ "pop_operand ax\nneg ax\npush_operand ax\n", (snd c1))
    )
  )
  | _ -> failwith "not implemented"
);;

(* TEST *)
let s = (compile (Apply(Val (Closure (Var 0)), Val(IntConst 10)))) in
print_string (fst s) ; print_string ("\n; functions\n" ^(snd s))
