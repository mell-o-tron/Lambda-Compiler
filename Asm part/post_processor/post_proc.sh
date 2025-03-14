#!/bin/bash

if [ -z "$1" ]
then
    echo "Please pass a filename"
    exit 1
fi

FILENAME="$1"

cp $FILENAME tmp
perl -0777 -pe 's/push_operand eax\npop_operand bx/;optimized\nmov bx, ax/sg' tmp > out.asm

cp out.asm tmp
perl -0777 -pe 's/push_operand ([0-9]+)\npop_operand (a|b)x/;optimized\nmov $2x, $1/sg' tmp > out.asm

cp out.asm tmp
perl -0777 -pe 's/push_operand eax\npop_operand bx/;(push-pop optimized away)\nmov bx, ax/sg' tmp > out.asm

cp out.asm tmp
perl -0777 -pe 's/create_bigint\ncall push_all_biginteger/;(biginteger push pop optimized away)/sg' tmp > out.asm

# cp out.asm tmp
# perl -0777 -pe 's/debufferize\nbufferize/debufferize\n;(bufferize after debufferize optimized away)/sg' tmp > out.asm

# TODO: Optimize away debufferize\nret\n;end_fun_*

rm tmp
echo "done post_processing"
