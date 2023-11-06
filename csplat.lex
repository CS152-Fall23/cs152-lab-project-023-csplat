%{
#include <math.h>
#include <stdio.h>

unsigned long long current_line = 1;
unsigned long long current_column = 0;
#define YY_USER_ACTION current_column += yyleng;

#include  "y.tab.c"

%}

%option noyywrap

IDENTIFIER  [a-z_][a-zA-Z0-9_]*
DIGIT       [0-9]
ASSIGNMENT  :=
RELOP		[>=<]|!=

%%
[ \t\r]+								{}
{DIGIT}+                                {   yylval.num = atoi(yytext); return NUM; }

[\+\-]									{	return ADDOP;	}
"*"										{	return MULOP;	}
"/"										{	return DIVOP;	}
{RELOP}									{	return RELOP;	}
":="									{	return ASSIGN;	}

";"										{	return SEMICOLON}
"("										{	return L_PAREN;	}
")"										{	return R_PAREN;	}
"{"										{	return LC;		}
"}"										{	return RC;		}
"?"										{	return QM;		}
"["										{	return LB;		}
"]"										{	return RB;		}
"\\"									{	return ESCAPE;	}

"whilst"								{	return WHILST;	}
"do"									{	return DO;		}
"stop"									{	return STOP;	}
"when"									{	return WHEN;	}
"else"									{	return ELSE;	}
"read"									{	return READ;	}
"write"									{	return WRITE;	}
"void"									{	return VOID;	}
"int"									{	return INT;		}
"return"								{	return RETURN;	}

{IDENTIFIER}                            { yylval.identifier = strdup(yytext); return IDENTIFIER; }
#[^\n]*                                 {/* eat up one-line comments */}
@#([^@]|(@+[^#]))*@#                    {/* eat up mult-line comments */}
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
	yyparse();

	return 0;
}
