%{
#include <math.h>
#include <stdio.h>

unsigned long long current_line = 1;
unsigned long long current_column = 0;
#define YY_USER_ACTION current_column += yyleng;
%}

%option noyywrap

IDENTIFIER  [a-z_][a-zA-Z0-9_]*
DIGIT       [0-9]
ASSIGNMENT  :=
ARITHMETIC  \+|\-|\*|\/
RELATION    >|=|<|!=
SYMBOL      [\{\}\[\]\(\)\?\\,;]
KEYWORD     whilst|dowhilst|stop|when|elsewhen|else|read|write|void|int|return

%%
[ \t\r]+								{}
{DIGIT}+                                {   printf("INT %d\n",atoi(yytext)); }
{ASSIGNMENT}                            {   printf("ASSIGNMENT OPERATER %s\n", yytext);}
{RELATION}                              {   printf("RELATION OPERATOR %s\n", yytext);}
{ARITHMETIC}                            {   printf("ARITHMETIC OPERATOR %s\n", yytext);}
{KEYWORD}               				{   printf("KEYWORD %s\n", yytext);}
#[^\n]*                                 {/* eat up one-line comments */}
@#([^@]|(@+[^#]))*@#                    {/* eat up mult-line comments */}
{SYMBOL}								{   printf("SYMBOL %s\n", yytext);}
{IDENTIFIER}                            {   printf("IDENTIFIER %s\n", yytext); }
\n          							{   ++current_line; current_column = 0;}

[A-Z0-9][a-zA-Z0-9_]*					{ printf( "Error at line %llu, column %llu: identifier \"%s\" must begin with a lower-case letter or underscore!\n", current_line, current_column, yytext); 
                                          yyterminate();
                                        }

.          								{ printf("Error at line %llu, col %llu : unrecognized symbol \"", current_line, current_column);
	                                      printf("%s\"\n", yytext);
	                                      yyterminate();
                                        }

%%


int main(int argc, char **argv){
	if(argc ==2 && !(yyin = fopen(argv[1], "r"))){
		fprintf(stderr, "could not open input file \n");
		return -1;
	}
	yylex();

	return 0;
}
