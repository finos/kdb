#!/bin/bash -eux

BUILD_DIR=../build
LEXER_BUILD_DIR="$BUILD_DIR"/lexer
INSTALL_DIR=../install
EXEC_DIR="$INSTALL_DIR"/bin

mkdir -p "$LEXER_BUILD_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$EXEC_DIR"

#Specifying the output location using lex is unreliable 
# TODO: Maybe better if this could just be a script.
#so we cd into the build directory and run lex without specifying -o or -output 
cp lexer/lex.l "$LEXER_BUILD_DIR"
#-output doesnt work reliably on RHEL5 so we cd into directory

#Generate .c file from lex.l
#no spaces can appear betwen -o and the path 
flex -o"$LEXER_BUILD_DIR"/lex.c lexer/lex.l

#Compile .c file 
gcc -o "$LEXER_BUILD_DIR"/qdoclex "$LEXER_BUILD_DIR"/lex.c  

#move lex file to install directory
cp "$LEXER_BUILD_DIR"/qdoclex "$EXEC_DIR"
cp qdoc "$EXEC_DIR"
cp qtabledoc "$EXEC_DIR"
