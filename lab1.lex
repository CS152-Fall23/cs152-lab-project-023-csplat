%{
    #include <math.h>
    #include <stdio.h>

    unsigned long long current_line = 1;
    unsigned long long current_column = 0;
    #define YY_USER_ACTION current_column += yyleng;
%}


%option noyywrap

IDENTIFIER  [a-z][a-z0-9_]*
DIGIT       [0-9]
SYMBOL      [\{\}\[\]\(\)\=\+\-\*\/\<\>\=\!=]


%%
[ \t\r]+
{DIGIT}+                                                                {   printf("INT %d\n",atoi(yytext)); }
:=                                                                      {   printf("ASSIGNMENT OPERATER %s\n", yytext);}
>|=|<|!=                                                                {   printf("RELATION OPERATOR %s\n", yytext);}
whilst|dowhilst|stop|if|elseif|else|read|write                          {   printf("KEYWORD %s\n", yytext);}
#[^\n]*                                                                 /* eat up one-line comments */
@#([^@]|(@+[^#]))*@#                                                    /* eat up mult-line comments */



{IDENTIFIER}                                                            {   printf("IDENTIFIER %s\n", yytext); }

\n          {   ++current_line; current_column = 0;}
.           {   printf("Error at line %llu, col %llu : unrecognized symbol \"", current_line, current_column);
                printf("%s\"", yytext);
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