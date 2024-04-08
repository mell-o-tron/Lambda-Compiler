open Parser

let digit = [%sedlex.regexp? '0' .. '9']
let number = [%sedlex.regexp? Plus digit]

let rec token lexbuf =
    match%sedlex lexbuf with
        | "λ" -> (Lambda)
        | "." -> (Dot)
        | "(" -> (LParens)
        | ")" -> (RParens)
        | "+" -> (Plus)
        | "-" -> (Minus)
        | "×" -> (Times)
        | "¬" -> (Not)
        | "∧" -> (And)
        | "∨" -> (Or)
        | "L" -> (Index)
        | "if" -> (If)
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