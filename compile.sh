flex csplat.flex
bison -v -d --file-prefix=y csplat.y
gcc -O3 lex.yy.c -o parser.elf
./parser.elf input.txt > output.txt
rm lex.yy.c y.output y.tab.c y.tab.h parser.elf
