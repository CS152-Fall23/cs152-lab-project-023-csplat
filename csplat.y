%{
#include "stdio.h"

int yylex (void);

void yyerror (char const *err) { fprintf(stderr, "yyerror: %s\n", err); exit(-1); }

%}

%define parse.error custom

%token NUM IDENTIFIER L_PAREN R_PAREN LC RC RB LB WHEN ELSE WHILST DO STOP READ WRITE VOID INT INT_ARRAY RETURN ASSIGN QM ESCAPE SEMICOLON

%left ADDOP MULOP DIVOP RELOP

%union {
   int num;
   char* identifier;
}

//%type<num> NUM stmt exp
//%type<identifier> IDENTIFIER

%%

program: stmts {}

stmts: stmt {}
| stmts stmt {}

stmt: declaration SEMICOLON {}
| assignment SEMICOLON {}

declaration: INT IDENTIFIER {}
| INT INT_ARRAY IDENTIFIER LB NUM RB {}

assignment: IDENTIFIER ASSIGN expression {}

expression: NUM {}
| IDENTIFIER LB NUM RB {}

stmt: when_stmt {}
| exp {}

when_stmt: WHEN L_PAREN exp R_PAREN LC stmts RC {}
| WHEN L_PAREN exp R_PAREN LC stmts RC ELSE LC stmts RC {}

exp: NUM {}
| L_PAREN exp R_PAREN {}

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
