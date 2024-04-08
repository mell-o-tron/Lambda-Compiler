open Ast

let function_counter = ref 0

let fresh_name () =
  function_counter := !function_counter + 1;
  "fun_" ^ string_of_int !function_counter
  
(* returns a pair of strings (s1, s2) where s1 is the code of the main expression, and s2 is the code of the generated functions *)

let rec compile (e: exp) = match e with
  | Lambda e1   ->  (
    let c = compile(e1) in let funname = fresh_name() in ("push_operand "^funname^"\n", funname ^":\n"^ (fst c) ^ "ret\n"^ (snd c))
  )
  (* gets operand from the environment stack, and pushes it to the operand stack *)
  | Var i -> ("push_operand [ENVIRONMENT_POINTER - " ^ string_of_int ((i + 1) * 2) ^ "]\n", "")
  
  (* in order to apply e1 to e2, first compile them, then pop the operands, push the parameter to the environment stack and call the retrieved function *)
  (* add any functions created by e1 and e2 to the function zone *)
  | Apply (e1, e2) -> let c1 = compile(e1) in let c2 = compile(e2) in
      ((fst c1) ^ (fst c2) ^ "pop_operand ax\npush_env ax\npop_operand ax\ncall ax\n", (snd c1) ^ (snd c2))
  
  | Aexp a -> (compile_aexp a)
  | Bexp b -> (compile_bexp b)
  | _ -> failwith "not implemented"


and compile_aexp (a: aexp) = match a with 
  | ABinop (o, e1, e2) -> (match o with
    | Plus -> let c1 = compile_aexp(e1) in let c2 = compile_aexp(e2) in
    ((fst c1) ^ (fst c2) ^ "pop_operand ax\npop_operand bx\nadd ax, bx\npush_operand ax\n", (snd c1) ^ (snd c2))
  )
  | AUnop (o, e1) -> (match o with
    | Neg -> let c1 = compile_aexp(e1) in
    ((fst c1) ^ "pop_operand ax\nneg ax\npush_operand ax\n", (snd c1))
  )
  | IntConst i  -> ("push_operand " ^ (string_of_int i) ^ "\n", "")


and compile_bexp (b: bexp) = match b with
  | BoolConst b -> ("push_operand " ^ (if b then "1" else "0") ^ "\n", "")
  | _ -> failwith "Not Implemented"