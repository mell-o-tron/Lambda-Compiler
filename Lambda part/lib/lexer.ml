open Parser

let digit = [%sedlex.regexp? '0' .. '9']
let hexNumber = [%sedlex.regexp? Plus hex_digit]
let number = [%sedlex.regexp? Plus digit | ("0x", hexNumber)]
let character = [%sedlex.regexp? 0x20 .. 0x7E]

let rec token lexbuf =
    match%sedlex lexbuf with
        | "λ."  | "\\lambda."  -> (Lambda)
        | "λs." | "\\lambdas." -> (Lambdas)
        | "@"                 -> (Apply)
        | "m@"                -> (MultiApply)
        | "$"                 -> (HOApply)
        | "("                 -> (LParens)
        | ")"                 -> (RParens)
        | "["                 -> (LSquare)
        | "]"                 -> (RSquare)
        | "+"                 -> (Plus)
        | "-"                 -> (Minus)
        | "×"  | "*"          -> (Times)
        | "/"                 -> (Div)
        | "b+"                -> (BigPlus)
        | "b-"                -> (BigMinus)
        | "b<="|"b≤"|"bleq"   -> (BigLeq)
        | "b>="|"b≥"|"bgeq"   -> (BigGeq)
        | "b<" |"blangle"     -> (BigLAngle)
        | "b>" |"brangle"     -> (BigRAngle)
        | "b=" |"beq"         -> (BigEq)
        | "b!="|"b≠"|"bneq"   -> (BigNeq)
        | "b*" |"bigtimes"    -> (BigTimes)
        | "b/"                -> (BigDiv)
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
        | "💀"|"☠"|"☠️"|"🕱"|"Die"        -> (Die)
        | "here" | "🙋"       -> (SayHere)
        | "bi"                -> (BigInt)
        | "'"                 -> (char lexbuf)
        | white_space         -> (token lexbuf)
        | ","                 -> (Comma)
        | ";"                 -> (Semicolon)
        | hexNumber,('H'|'h') -> (Number (int_of_string ("0x" ^ (let x = Sedlexing.Latin1.lexeme lexbuf in String.sub x 0 ((String.length x) - 1)))))
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
