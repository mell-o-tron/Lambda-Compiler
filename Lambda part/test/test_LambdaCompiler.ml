module Ast = LambdaCompiler.Ast
module C = LambdaCompiler.Compiler

(* TEST *)

let s = (C.compile (Ast.Apply (Ast.Lambda (Ast.Aexp(Ast.ABinop(Ast.Plus, Ast.Aexp(Ast.IntConst 5), Ast.Var 0))), Ast.IfThenElse(Ast.Bexp(Ast.Compare(Ast.Equals, Ast.Aexp(Ast.IntConst 4), Ast.Aexp(Ast.IntConst 6))), Ast.Aexp(Ast.IntConst 3), Ast.Aexp(Ast.IntConst 64)))));;

print_string (fst s);
print_string ("\n; functions\n" ^(snd s))
