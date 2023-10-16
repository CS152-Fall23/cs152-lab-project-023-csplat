%{
#include <stdio.h>

int lineNum = 1;
int colNum = 1;
%}

DIGIT  [0-9]
ALPHA  [a-zA-Z]
SYMBOL [\{\}\[\]\(\)\=\+\-\*\/\<\>\=\!=]

%%
" "+      { colNum++; }
\n        { lineNum++; colNum = 1; }
;	      { printf("SEMICOLON\n"); colNum++; }
"int"     { printf("INTEGER\n"); colNum++; }
"{"       { printf("L_BRACE\n"); colNum++; }
"}"       { printf("R_BRACE\n"); colNum++; }
"["       { printf("L_BRACKET\n"); colNum++; }
"]"       { printf("R_BRACKET\n"); colNum++; }
"("       { printf("L_PARENTHESIS\n"); colNum++; }
")"       { printf("R_PARENTHESIS\n"); colNum++; }
"[]"      { printf("ARRAY\n"); colNum++; }
"="       { printf("EQUALS\n"); colNum++; }
"+"       { printf("PLUS\n"); colNum++; }
"-"       { printf("MINUS\n"); colNum++; }
"*"       { printf("MULTIPLY\n"); colNum++; }
"/"       { printf("DIVIDE\n"); colNum++; }
"<"       { printf("LESS_THAN\n"); colNum++; }
">"       { printf("GREATER_THAN\n"); colNum++; }
"!="	  { printf("NOT_EQUAL_TO\n"); colNum++;}
%%
