#!/bin/bash

if [ -z "$1" ]
then
    echo "Please pass a filename"
    exit 1
fi

FILENAME="$1"

perl -0777 -pe 's/push_operand eax\npop_operand bx/;optimized\nmov bx, ax/sg' $FILENAME > tmp
perl -0777 -pe 's/push_operand ([0-9]+)\npop_operand (a|b)x/;optimized\nmov $2x, $1/sg' tmp > tmp1

perl -0777 -pe 's/push_operand eax\npop_operand bx/;(push-pop optimized away)\nmov bx, ax/sg' tmp1 > out.asm

perl -0777 -pe 's/create_bigint\ncall push_all_biginteger/;(biginteger push pop optimized away)/sg' out.asm > final_output.asm

mv final_output.asm out.asm

rm tmp
rm tmp1

echo "done post_processing"
