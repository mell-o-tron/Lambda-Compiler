open Ast

let function_counter = ref 0

let fresh_name () =
  function_counter := !function_counter + 1;
  "fun_" ^ string_of_int !function_counter
  
let jmp_counter = ref 0

let fresh_jmp () =
  jmp_counter := !jmp_counter + 1;
  "branch_" ^ string_of_int !jmp_counter
  
  
(* returns a pair of strings (s1, s2) where s1 is the code of the main expression, and s2 is the code of the generated functions *)

let rec compile (e: exp) = (match e with
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
  | IfThenElse (e1, e2, e3) -> 
          let c1 = compile e1 in
          let c2 = compile e2 in
          let c3 = compile e3 in
          let l1 = fresh_jmp() in
          let l2 = fresh_jmp() in
          ( fst c1 ^ "pop_operand ax\ncmp ax, 1 \njne " ^ l1 ^ "\n" ^ (fst c2) ^ "\njmp " ^ l2 ^ "\n"^ l1 ^":\n" ^ (fst c3) ^ "\n" ^ l2 ^ ":\n",
            snd c1 ^ snd c2 ^ snd c3 ))


and compile_aexp (a: aexp) =  (match a with
  | ABinop (o, e1, e2) ->
          let op = (match o with 
            | Plus -> "add" 
            | _ -> failwith("abop not yet implemented")
          ) in
          let c1 = compile e1 in
          let c2 = compile e2 in
          ( fst c1 ^ fst c2 ^ "pop_operand ax\npop_operand bx\n" ^ op
            ^ " ax, bx\npush_operand ax\n",
            snd c1 ^ snd c2 )
  | AUnop (o, e1) ->
          let op = (match o with 
            | Neg -> "neg"
            (*| _ -> failwith("auop not yet implemented")*)
          )in
          let c1 = compile e1 in
          (fst c1 ^ "pop_operand ax\n" ^ op ^ " ax\npush_operand ax\n", snd c1)
  
  | IntConst i  -> ("push_operand " ^ (string_of_int i) ^ "\n", ""))


and compile_bexp (b: bexp) = (match b with
  | BoolConst b -> ("push_operand " ^ (if b then "1" else "0") ^ "\n", "")
  | BBinop (o, e1, e2) ->
          let op = (match o with 
            | And -> "and" 
            | Or -> "or"
            (*| _ -> failwith("boolean operator not yet implemented")*)
          ) in
          let c1 = compile e1 in
          let c2 = compile e2 in
          ( fst c1 ^ fst c2 ^ "pop_operand ax\npop_operand bx\n" ^ op
            ^ " ax, bx\npush_operand ax\n",
            snd c1 ^ snd c2 )
      | BUnop (o, e1) ->
          let op = match o with Not -> "not" in
          let c1 = compile e1 in
          (fst c1 ^ "pop_operand ax\n" ^ op ^ " ax\npush_operand ax\n", snd c1)
          
      | Compare (o, e1, e2) -> 
          let op = (match o with 
            | Equals -> "jne" 
            | LessThan -> "jge"
            | _ -> failwith("comparator not yet implemented")
          ) in
          let c1 = compile e1 in
          let c2 = compile e2 in
          let l1 = fresh_jmp() in
          let l2 = fresh_jmp() in
          ( fst c1 ^ fst c2 ^ "pop_operand ax\npop_operand bx\ncmp ax, bx \n" ^ op ^ " " ^ l1 ^ "\npush_operand 1\njmp " ^ l2 ^ "\n"^ l1 ^":\npush_operand 0\n" ^ l2 ^ ":\n",
            snd c1 ^ snd c2 ));;
            
