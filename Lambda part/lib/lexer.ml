open Parser

let digit = [%sedlex.regexp? '0' .. '9']
let number = [%sedlex.regexp? Plus digit]

let rec token lexbuf =
    match%sedlex lexbuf with
        | "λ."   -> (Lambda)
        | "("    -> (LParens)
        | ")"    -> (RParens)
        | "+"    -> (Plus)
        | "-"    -> (Minus)
        | "×"    -> (Times)
        | "¬"    -> (Not)
        | "∧"    -> (And)
        | "∨"    -> (Or)
        | "="    -> (Equals)
        | "≠"    -> (Neq)
        | "≥"    -> (Geq)
        | "≤"    -> (Leq)
        | "L"    -> (LIndex)
        | "F"    -> (FIndex)
        | "if"   -> (If)
        | "then" -> (Then)
        | "else" -> (Else)
        | white_space -> (token lexbuf)
        | number -> (
            Number (int_of_string (Sedlexing.Latin1.lexeme lexbuf))
        )
        | eof -> (EOF)
        | any -> (
            failwith  (Printf.sprintf "Unrecognised character: \'%s\'" (Sedlexing.Latin1.lexeme lexbuf))
        )
        | _ -> (failwith "Impossible!")
let tokenize (lexbuf: Sedlexing.lexbuf) =
    token lexbuf