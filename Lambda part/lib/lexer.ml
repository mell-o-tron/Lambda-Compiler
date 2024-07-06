open Parser

let digit = [%sedlex.regexp? '0' .. '9']
let number = [%sedlex.regexp? Plus digit]

let rec token lexbuf =
    match%sedlex lexbuf with
        | "λ." | "\\lambda."  -> (Lambda)
        | "@"                 -> (Apply)
        | "$"                 -> (HOApply)
        | "("                 -> (LParens)
        | ")"                 -> (RParens)
        | "+"                 -> (Plus)
        | "-"                 -> (Minus)
        | "×"  | "*"          -> (Times)
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

let tokenize (lexbuf: Sedlexing.lexbuf) =
    token lexbuf
