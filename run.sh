#!/bin/bash

if [ -z "$1" ]
then
    echo "Please pass a filename"
    exit 1
fi

FILENAME="$(pwd)/$1"
echo "$FILENAME"

cd "Lambda part"
make build

mkdir -p build
_build/default/bin/compiler.exe "$FILENAME" build/y.asm
if [ $? -ne 0 ]
then
    echo "There was an error compiling the expression"
    exit 1
fi

cd "../Bootloader part"
make
