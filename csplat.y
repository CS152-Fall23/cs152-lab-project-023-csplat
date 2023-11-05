%{
#include "stdio.h"

int yylex (void);

void yyerror (char const *err) { fprintf(stderr, "yyerror: %s\n", err); exit(-1); }

%}

%define parse.error custom

%token NUM IDENTIFIER L_PAREN R_PAREN LC RC RB LB WHEN ELSE WHILST DO STOP READ WRITE VOID INT RETURN ASSIGN QM ESCAPE

%left ADD SUB MUL DIV RELOP

%union {
   int num;
}

//%type<num> NUM stmt exp

%%

program: stmts { printf("stmts\n");}
| program stmt { printf("program stmt\n");}

stmts: add_exp ASSIGN { printf("add_exp ASSIGN\n");}
| exp { printf("exp\n");}

stmt: when_stmt { printf("when_stmt\n");}


when_stmt: WHEN L_PAREN exp R_PAREN LC stmts RC { printf("WHEN L_PAREN exp R_PAREN LC stmts RC\n");}
| WHEN L_PAREN exp R_PAREN LC stmts RC ELSE LC stmts RC { printf("WHEN L_PAREN exp R_PAREN LC stmts RC ELSE LC stmts RC\n");}

add_exp: mul_exp { printf("mul_exp\n");}
| add_exp ADD add_exp { printf("add_exp ADD add_exp\n");}
| add_exp SUB add_exp { printf("add_exp SUB add_exp\n");}

mul_exp: exp { printf("exp\n");}
| mul_exp MUL mul_exp { printf("mul_exp MUL mul_exp\n");}
| mul_exp DIV mul_exp { printf("mul_exp DIV mul_exp\n");}

exp: NUM { printf("NUM\n");}
| SUB exp { printf("SUB exp\n");}
| L_PAREN add_exp R_PAREN { printf("L_PAREN add_exp R_PAREN\n");}


%%

static int yyreport_syntax_error(const yypcontext_t *ctx) {
	yysymbol_kind_t tokenCausingError = yypcontext_token(ctx);
	yysymbol_kind_t expectedTokens[YYNTOKENS];
	int numExpectedTokens = yypcontext_expected_tokens(ctx, expectedTokens, YYNTOKENS);
	
	fprintf(stderr, "\n-- Syntax Error --\n");
	fprintf(stderr, "%llu line, %llu column\n", current_line, current_column);
	fprintf(stderr, "Token causing error: %s\n", yysymbol_name(tokenCausingError));
	for (int i = 0; i < numExpectedTokens; ++i) {
		fprintf(stderr, " expected token (%d/%d): %s\n", i+1, numExpectedTokens, yysymbol_name(expectedTokens[i]));
	}
	return 0;
}
