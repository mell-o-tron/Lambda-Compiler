exception Syntax_error of (Lexing.position * Lexing.position) * string
let inchn = open_in Sys.argv.(1);;


let ast_of_channel inchn =
  let lexbuf = Sedlexing.Latin1.from_channel inchn in
  let lexer  = Sedlexing.with_tokenizer LambdaCompiler.Lexer.token lexbuf in
  let parser = MenhirLib.Convert.Simplified.traditional2revised LambdaCompiler.Parser.program in
  try (parser lexer) with
  | LambdaCompiler.Parser.Error ->
    raise (Syntax_error ((Sedlexing.lexing_positions lexbuf), "Syntax error"));;

Printf.printf "%s" (LambdaCompiler.Ast.show_exp (ast_of_channel inchn));;


close_in inchn