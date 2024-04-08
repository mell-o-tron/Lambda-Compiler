module Ast = LambdaCompiler.Ast
module C = LambdaCompiler.Compiler

(* TEST *)
let s = (C.compile (Ast.Apply (Ast.Lambda (Ast.Var 0), Ast.Aexp(Ast.IntConst 10))));;

print_string (fst s);
print_string ("\n; functions\n" ^(snd s))
