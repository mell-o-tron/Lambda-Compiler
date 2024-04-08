let inchn = open_in Sys.argv.(1);;

LambdaCompiler.Lexer.tokenize (Sedlexing.Latin1.from_channel inchn);;

close_in inchn