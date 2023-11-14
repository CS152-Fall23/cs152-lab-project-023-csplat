flex csplat.lex
bison -v -d --file-prefix=y csplat.y
gcc -O3 lex.yy.c -o parser.elf
./parser.elf input.txt > output.txt
./mil_run output.txt
