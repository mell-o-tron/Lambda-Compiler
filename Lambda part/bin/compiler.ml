open LambdaCompiler.Ast
exception Syntax_error of int * int * string

let function_counter = ref 0

let fresh_name () =
  function_counter := !function_counter + 1;
  "fun_" ^ string_of_int !function_counter
  
let jmp_counter = ref 0

let fresh_jmp () =
  jmp_counter := !jmp_counter + 1;
  "branch_" ^ string_of_int !jmp_counter
  

(* returns a pair of strings (s1, s2) where s1 is the code of the main expression, and s2 is the code of the generated functions *)

let rec compile (e: exp) (depth:int) = (match e with
  | Lambda e1   ->  (
    let c = compile(e1)(depth + 1) in let funname = fresh_name() in ("push_operand "^funname^"\n" ^ "push_operand CURRENT_RECORD\n", 
                                                          funname ^":\n"^ (fst c) ^ 
                                                          "bufferize\nret\n\n"
                                                          ^ (snd c))
  )

  | Var i -> (
    if i < 0
      then ("pusha\nmov bx, 6969\ncall print_dec\npopa", "")
      else ("mov ax, " ^ string_of_int i ^ "\ncall seekle\n", "")
  )

  | Apply (e1, e2) -> let c1 = compile(e1)(depth) in let c2 = compile(e2)(depth) in
      ((fst c1) ^ (fst c2) ^ "make_record\ncall bx\ndebufferize\n", (snd c1) ^ (snd c2))
      
    (* dirty! pops the extra record off the operand stack... do we somehow need it? *)
  | HOApply (e1, e2) -> let c1 = compile(e1)(depth) in let c2 = compile(e2)(depth) in
      ((fst c1) ^ (fst c2) ^ "make_HO_record\ncall bx\ndebufferize\n", (snd c1) ^ (snd c2))
  
  | Aexp a -> (compile_aexp a depth)
  | Bexp b -> (compile_bexp b depth)
  | IfThenElse (e1, e2, e3) -> 
          let c1 = compile e1 (depth) in
          let c2 = compile e2 (depth) in
          let c3 = compile e3 (depth) in
          let l1 = fresh_jmp() ^ "_else" in
          let l2 = fresh_jmp() ^ "_endif" in
          ( fst c1 ^ "pop_operand ax\ncmp ax, 1 \njne " ^ l1 ^ "\n; then:\n" ^ (fst c2) ^ "\njmp " ^ l2 ^ "\n"^ l1 ^":\n; else:\n" ^ (fst c3) ^ "\n" ^ l2 ^ ":\n",
            snd c1 ^ snd c2 ^ snd c3 )
  | Interrupt (e) ->
          let cn =  compile (Apply (e, Aexp(IntConst(0)))) (depth) in
          let c1 = compile (Apply (e,  Aexp(IntConst(1)))) (depth) in
          let c2 = compile (Apply (e,  Aexp(IntConst(2)))) (depth) in
          let c3 = compile (Apply (e,  Aexp(IntConst(3)))) (depth) in
          let c4 = compile (Apply (e,  Aexp(IntConst(4)))) (depth) in
          let c5 = compile (Apply (e,  Aexp(IntConst(5)))) (depth) in
          let c6 = compile (Apply (e,  Aexp(IntConst(6)))) (depth) in
          let c7 = compile (Apply (e,  Aexp(IntConst(7)))) (depth) in
          let c8 = compile (Apply (e,  Aexp(IntConst(8)))) (depth) in
          let cb = compile (Apply (e,  Aexp(IntConst(9)))) (depth) in
          ("pusha\n" ^ fst c8 ^ fst c7 ^ fst c6 ^ fst c5 ^ fst c4 ^ fst c3 ^ fst c2 ^ fst c1 ^ fst cn ^
          "call_interrupt\npopa\n" ^ fst cb ^ "call_callback\n",
          snd cn ^ snd c1 ^ snd c2 ^ snd c3 ^ snd c4 ^ snd c5 ^ snd c6 ^ snd c7 ^ snd c8 ^ snd cb)

  | Die -> ("jmp death", "")
  
  )


and compile_aexp (a: aexp) (depth : int) =  (match a with
  | ABinop (o, e1, e2) ->
          let op = (match o with 
            | Plus -> "add_integers" 
            | Times -> "mul_integers" 
            | Div -> "div_integers" 
(*             | _ -> failwith("abop not yet implemented") *)
          ) in
          let c1 = compile e1 (depth) in
          let c2 = compile e2 (depth) in
          ( fst c1 ^ fst c2 ^ "pop_operand bx\npop_operand ax\n" ^ op
            ^ "\n",
            snd c1 ^ snd c2 )
  | AUnop (o, e1) ->
          let op = (match o with 
            | Neg -> "neg"
            (*| _ -> failwith("auop not yet implemented")*)
          )in
          let c1 = compile e1 (depth) in
          (fst c1 ^ "pop_operand ax\n" ^ op ^ " ax\npush_operand eax\n", snd c1)
  
  | IntConst i  -> ("push_operand " ^ (string_of_int i) ^ "\n", ""))


and compile_bexp (b: bexp) (depth : int) = (match b with
  | BoolConst b -> ("push_operand " ^ (if b then "1" else "0") ^ "\n", "")
  | BBinop (o, e1, e2) ->
          let op = (match o with 
            | And -> "and" 
            | Or -> "or"
            (*| _ -> failwith("boolean operator not yet implemented")*)
          ) in
          let c1 = compile e1 (depth) in
          let c2 = compile e2 (depth) in
          ( fst c1 ^ fst c2 ^ "pop_operand bx\npop_operand ax\n" ^ op
            ^ " ax, bx\npush_operand eax\n",
            snd c1 ^ snd c2 )
      | BUnop (o, e1) ->
          let op = match o with Not -> "not" in
          let c1 = compile e1 (depth) in
          (fst c1 ^ "pop_operand ax\n" ^ op ^ " ax\npush_operand eax\n", snd c1)
          
      | Compare (o, e1, e2) -> 
          let op = (match o with 
            | Equals        -> "jne" 
            | LessThan      -> "jge"
            | GreaterThan   -> "jle"
            | LessEqual     -> "jg"
            | GreaterEqual  -> "jl"
            | NotEqual      -> "je"
(*             | _ -> failwith("comparator not yet implemented") *)
          ) in
          let c1 = compile e1 (depth) in
          let c2 = compile e2 (depth) in
          let l1 = fresh_jmp() ^ "_cmp_fail" in
          let l2 = fresh_jmp() ^ "_end_cmp" in
          ( fst c1 ^ fst c2 ^ "pop_operand bx\npop_operand ax\ncmp ax, bx \n" ^ op ^ " " ^ l1 ^ "\npush_operand 1 ; cmp true\njmp " ^ l2 ^ "\n"^ l1 ^":\npush_operand 0 ; cmp false\n" ^ l2 ^ ":\n",
            snd c1 ^ snd c2 ));;
            


let inchn = open_in Sys.argv.(1);;

let ast_of_channel inchn =
  let lexbuf = Sedlexing.Latin1.from_channel inchn in
  let lexer  = Sedlexing.with_tokenizer LambdaCompiler.Lexer.token lexbuf in
  let parser = MenhirLib.Convert.Simplified.traditional2revised LambdaCompiler.Parser.program in
  try (parser lexer) with
  | LambdaCompiler.Parser.Error ->
    raise (Syntax_error ((fst (Sedlexing.lexing_positions lexbuf)).pos_lnum, (fst (Sedlexing.lexing_positions lexbuf)).pos_cnum, "Syntax error"));;

let ast = ast_of_channel inchn in
let compiled = compile ast 0 in

let outchn = open_out (Sys.argv.(2) ^ ".program") in
Printf.fprintf outchn "%s" (fst compiled) ;

let outchn = open_out (Sys.argv.(2) ^ ".functions") in
Printf.fprintf outchn "%s" (snd compiled) ;

Printf.printf "%s\n" (LambdaCompiler.Ast.show_exp ast);;

close_in inchn
