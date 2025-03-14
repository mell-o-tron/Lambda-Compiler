#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CALLING_DIR="$(pwd)"

if [ -z "$1" ]
then
    echo "Postprocessor says: Please pass a filename"
    exit 1
fi

FILENAME="$CALLING_DIR/$1"
echo "$FILENAME"

cd "$SCRIPT_DIR/Lambda part"
make build

mkdir -p build
_build/default/bin/compiler.exe "$FILENAME" build/y.asm
if [ $? -ne 0 ]
then
    echo "There was an error compiling the expression"
    exit 1
fi

cd "$SCRIPT_DIR/Asm part"
make all
