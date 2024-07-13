open Parser

let digit = [%sedlex.regexp? '0' .. '9']
let number = [%sedlex.regexp? Plus digit]
let character = [%sedlex.regexp? 0x20 .. 0x7E]

let rec token lexbuf =
    match%sedlex lexbuf with
        | "λ." | "\\lambda."  -> (Lambda)
        | "\\lambdas."         -> (Lambdas)
        | "@"                 -> (Apply)
        | "$"                 -> (HOApply)
        | "("                 -> (LParens)
        | ")"                 -> (RParens)
        | "+"                 -> (Plus)
        | "-"                 -> (Minus)
        | "×"  | "*"          -> (Times)
        | "/"                 -> (Div)
        | "¬"  | "!"          -> (Not)
        | "∧"  | "&"          -> (And)
        | "∨"  | "|"          -> (Or)
        | "="                 -> (Equals)
        | "≠"  | "!="         -> (Neq)
        | "≥"  | ">="         -> (Geq)
        | "≤"  | "<="         -> (Leq)
        | "<"                 -> (LAngle)
        | ">"                 -> (RAngle)
        | "L"                 -> (LIndex)
        | "G"                 -> (GIndex)
        | "if"                -> (If)
        | "then"              -> (Then)
        | "else"              -> (Else)
        | "Y"                 -> (Ycomb)
        | "INT"               -> (Interrupt)
        | "'"                 -> (char lexbuf)
        | white_space         -> (token lexbuf)
        | ","                 -> (Comma)
        | number              -> (
            Number (int_of_string (Sedlexing.Latin1.lexeme lexbuf))
        )
        | "**"                -> (comment lexbuf)
        | eof                 -> (EOF)
        | any                 -> (
            failwith  (Printf.sprintf "Unrecognised character: \'%s\'" (Sedlexing.Latin1.lexeme lexbuf))
        )
        | _                   -> (failwith "Impossible!")

and comment lexbuf =
    match%sedlex lexbuf with
        | "**"                -> (token lexbuf)
        | "\n"                -> (token lexbuf)
        | eof                 -> (EOF)
        | any                 -> (comment lexbuf)
        | _                   -> (failwith "Impossible!")

and char lexbuf =
    match%sedlex lexbuf with
        | character, "'"      -> Character (Sedlexing.Latin1.lexeme lexbuf).[0]
        | _                   -> failwith "Character not closed by a quote!"

let tokenize (lexbuf: Sedlexing.lexbuf) =
    token lexbuf
