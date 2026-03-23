@echo off

set NAME=ANSI

if not exist zmac\zmac.exe start /w getzmac.sh

::Assemble ANSI driver
zmac\zmac --mras %NAME%.ASM  -o %NAME%.cim -o %NAME%.lst -c
if errorlevel 1 goto :eof

move /Y %NAME%.cim %NAME%.com
