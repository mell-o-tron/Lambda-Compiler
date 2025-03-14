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
  
  | Lambdas (n, e1) -> if n = 0 then compile(e1)(depth) else
                       compile(Lambda(Lambdas(n-1, e1)))(depth)    (*unroll multi-lambda*)
  
  | MultiApply (e1, l) -> ( match l with
      | []    -> compile(e1) (depth)
      | x::xs -> compile(MultiApply (Apply(e1, x), xs))(depth)
  )
  
  | Lambda e1   ->  (
    let c = compile(e1)(depth + 1) in let funname = fresh_name() in ("push_operand "^funname^"\n" ^ "push_operand CURRENT_RECORD\n", 
                                                          funname ^":\n"^ (fst c) ^ 
                                                          "bufferize\nret\n;end_" ^ funname ^"\n\n"
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
          let l1 = fresh_jmp() ^ "_else" in
          let f_tuple = fresh_name () ^ "_tuple" in
          let ct = (match e with 
            | Lambda e1 -> compile_named_lambda e1 f_tuple depth
            | _ -> failwith "interrupt argument is not a tuple"
          ) in
          let cn = call_tuple f_tuple 0 in
          let c1 = call_tuple f_tuple 1 in
          let c2 = call_tuple f_tuple 2 in
          let c3 = call_tuple f_tuple 3 in
          let c4 = call_tuple f_tuple 4 in
          let c5 = call_tuple f_tuple 5 in
          let c6 = call_tuple f_tuple 6 in
          let c7 = call_tuple f_tuple 7 in
          let c8 = call_tuple f_tuple 8 in
          let cb = call_tuple f_tuple 9 in
          (c8 ^ c7 ^ c6 ^ c5 ^ c4 ^ c3 ^ c2 ^ c1 ^ cn ^
          "pusha\ncall_interrupt " ^ l1 ^ "\npopa\n" ^ cb ^ "call_callback\n",
          snd ct)

  | Switch (lst, n) -> let (c, l) = compile_switch_params lst in ("mov ax, " ^ (string_of_int n) ^ "\ncall seekle\npop_operand ax\n" ^ compile_switch_jmps (l) (0) ^ fst c
    , snd c
  )
          
  | Die -> ("jmp death\n", "")

  | SayHere (e) -> let c1 = compile e depth in ("say_here\n" ^ (fst c1), (snd c1))
  
  | Bigexp(e) -> compile_bigexp (e) (depth)
  )

and compile_bigexp (e) (depth) = match e with
  | BigInt(i) -> compile_bigint(i)(depth)
  | BigBinop (op, e1, e2) -> ( match op with
    | BigPlus -> let c1 = (pushall_bigint e1 depth) in let c2 = (pushall_bigint e2 depth) in
    (fst c1 ^ fst c2 ^ 
      "call add_bigintegers\ncreate_bigint\n", snd c1 ^ snd c2)
    | BigDiv -> let c1 = (pushall_bigint e1 depth) in let c2 = (pushall_bigint e2 depth) in
    (fst c1 ^ fst c2 ^ 
      "call divide_bigint\ncreate_bigint\n", snd c1 ^ snd c2)
    | BigTimes -> let c1 = (pushall_bigint e1 depth) in let c2 = (pushall_bigint e2 depth) in
    (fst c1 ^ fst c2 ^ 
      "call multiply_bigint\ncreate_bigint\n", snd c1 ^ snd c2)
      

    (* | _ -> failwith("this bigbinop is not implemented") *)
  )
  | BigUnop (op, e) -> ( match op with
    | BigNeg -> let c = (pushall_bigint e depth) in
      (fst c ^

      "call negate_bigint\ncreate_bigint\n", snd c)
    )
  | BigCompare (op, e1, e2) -> 
      let op = (match op with 
                | BigEquals        -> "jne" 
                | BigLessThan      -> "jge"
                | BigGreaterThan   -> "jle"
                | BigLessEqual     -> "jg"
                | BigGreaterEqual  -> "jl"
                | BigNotEqual      -> "je"
    (*             | _ -> failwith("bigcomparator not yet implemented") *)
              ) in
              let c1 = (pushall_bigint e1 depth) in
              let c2 = (pushall_bigint e2 depth) in
              let l1 = fresh_jmp() ^ "_big_cmp_fail" in
              let l2 = fresh_jmp() ^ "_end_big_cmp" in
              ( fst c1 ^ fst c2 ^ "call cmp_bigintegers\n" ^ op ^ " " ^ l1 ^ "\npush_operand 1 ; bigcmp true\njmp " ^ l2 ^ "\n"^ l1 ^":\npush_operand 0 ; bigcmp false\n" ^ l2 ^ ":\n",
                snd c1 ^ snd c2 )
  
and pushall_bigint (e) (depth) =
  let c = compile e depth in
  (fst c ^ "call push_all_biginteger\n", snd c)
  




(* For now can only initialize bigint with 64-bit int -- actually 63 because ocaml*)
(* and compile_bigint (i : int)(_depth : int)= 
let ll = i land 0xFFFF in
let lh = (i lsr 16) land 0xFFFF in
let hl = (i lsr 32) land 0xFFFF in
let hh = (i lsr 48) land 0xFFFF lor 
  (if i < 0 then  0b1000000000000000 else   (* to account for ocaml's weirdness *)
                  0) in
("; making bigint\nmov eax, "   ^ Int.to_string hh ^ "\npush_operand eax\n" ^
 "mov eax, "   ^ Int.to_string hl ^ "\npush_operand eax\n" ^
 "mov eax, "   ^ Int.to_string lh ^ "\npush_operand eax\n" ^
 "mov eax, "   ^ Int.to_string ll ^ "\npush_operand eax\ncreate_bigint\n", "") *)
(* For now can only initialize bigint with 64-bit int -- actually 63 because ocaml*)
and compile_bigint (i : int)(depth : int)= 
  let ll = i land 0xFFFF in
  let lh = (i lsr 16) land 0xFFFF in
  let hl = (i lsr 32) land 0xFFFF in
  let hh = (i lsr 48) land 0xFFFF lor 
    (if i < 0 then  0b1000000000000000 else   (* to account for ocaml's weirdness *)
                    0) in
  compile ((Lambda                         
   (IfThenElse (
      (Bexp
         (Compare (Equals, (Var 0), (Aexp (IntConst 0))))),
      (Aexp (IntConst ll)),
      (IfThenElse (
         (Bexp
            (Compare (Equals, (Var 0),
               (Aexp (IntConst 1))))),
         (Aexp (IntConst lh)),
         (IfThenElse (
            (Bexp
               (Compare (Equals, (Var 0),
                  (Aexp (IntConst 2))))),
            (Aexp (IntConst hl)),
            (IfThenElse (
               (Bexp
                  (Compare (Equals, (Var 0),
                     (Aexp (IntConst 3))))),
               (Aexp (IntConst hh)), Die))
            ))
         ))
      ))))(depth + 1)
  
  
  
  

and compile_switch_params (lst : exp list) = (match lst with
  | []            ->  (("",""), [])
  | e :: lst1     ->  let c1 = compile_switch_params (lst1) in
                      let l1 = fresh_jmp() ^ "_switch" in 
                      let c  = compile e 0 in ((l1 ^ ":\n" ^ fst c ^ "bufferize\nret\n" ^ fst (fst c1), snd c ^ snd (fst c1)), l1 :: snd c1)
)
  
and compile_switch_jmps (lst : string list) (n : int) = (match lst with
  | []            -> fst(compile (Die) (0))
  | e :: lst1      -> "cmp ax, " ^ (string_of_int n) ^ "\nje " ^ e ^ "\n" ^ (compile_switch_jmps lst1 (n+1))

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
            snd c1 ^ snd c2 ))
            
  and compile_named_lambda (e1 : exp) (funname : string) (depth : int) = 
    let c = compile(e1)(depth + 1) in ("push_operand "^funname^"\n" ^ "push_operand CURRENT_RECORD\n", funname ^":\n"^ (fst c) ^ "bufferize\nret\n\n" ^ (snd c))
  
  and call_tuple (funname : string) (i : int) = "push_operand " ^ funname ^ "\npush_operand CURRENT_RECORD\npush_operand " ^ (string_of_int i) ^ "\nmake_record\ncall bx\ndebufferize\n"
  ;;
            


let inchn = open_in Sys.argv.(1);;

let ast_of_channel inchn =
  let lexbuf = Sedlexing.Latin1.from_channel inchn in
  let lexer  = Sedlexing.with_tokenizer LambdaCompiler.Lexer.token lexbuf in
  let parser = MenhirLib.Convert.Simplified.traditional2revised LambdaCompiler.Parser.program in
  try (parser lexer) with
  | LambdaCompiler.Parser.Error ->
    raise
      (Syntax_error
         ( (fst (Sedlexing.lexing_positions lexbuf)).pos_lnum,
           (fst (Sedlexing.lexing_positions lexbuf)).pos_cnum
           - (fst (Sedlexing.lexing_positions lexbuf)).pos_bol,
           "Syntax error" ));;


let ast = ast_of_channel inchn in
let compiled = compile ast 0 in

let outchn = open_out (Sys.argv.(2) ^ ".program") in
Printf.fprintf outchn "%s" (fst compiled) ;

let outchn = open_out (Sys.argv.(2) ^ ".functions") in
Printf.fprintf outchn "%s" (snd compiled) ;

Printf.printf "%s\n" (LambdaCompiler.Ast.show_exp ast);;

close_in inchn
