%{
#include "stdio.h"

int yylex (void);

void yyerror (char const *err) { fprintf(stderr, "yyerror: %s\n", err); exit(-1); }

%}

%define parse.error custom

%token NUM IDENTIFIER L_PAREN R_PAREN LC RC RB LB WHEN ELSE WHILST DO STOP READ WRITE VOID INT RETURN ASSIGN QM ESCAPE SEMICOLON COMMA

%left ADD SUB MUL DIV REL

%union {
   int num;
}

//%type<num> NUM stmt exp

%%

program: stmts { printf("program -> stmts\n");}

stmts: stmts stmt {printf("stmt -> stmt\n");}
|stmt {printf("stmts -> stmt\n");}

add_exp: mul_exp { printf("add_exp -> mul_exp\n");}
| add_exp ADD add_exp { printf("add_exp -> add_exp ADD add_exp\n");}
| add_exp SUB add_exp { printf("add_exp -> add_exp SUB add_exp\n");}

mul_exp: exp { printf("mul_exp -> exp\n");}
| mul_exp MUL mul_exp { printf("mul_exp -> mul_exp MUL mul_exp\n");}
| mul_exp DIV mul_exp { printf("mul_exp -> mul_exp DIV mul_exp\n");}

exp: NUM { printf("exp -> NUM\n");}
| SUB exp { printf("exp -> SUB exp\n");}
| L_PAREN add_exp R_PAREN { printf("exp -> L_PAREN add_exp R_PAREN\n");}
| rel_exp {printf("exp -> rel_exp\n");}
| function_call {printf("exp -> function_call\n");}
| IDENTIFIER {printf("exp -> IDENTIFIER\n");}

rel_exp: exp REL exp {printf("rel_exp -> add_exp REL ad_exp\n");}

stmt: IDENTIFIER ASSIGN add_exp SEMICOLON { printf("stmt -> IDENTIFIER ASSIGN exp\n");}
| when_stmt {printf("stmt -> when_stmt\n");}
| whilst_stmt {printf("stmt -> whilst_stmt\n");}
| dowhilst_stmt {printf("stmt -> dowhilst_stmt\n");}
| function {printf("stmt -> function\n");}
| return_stmt {printf("stmt -> return_stmt\n");}

return_stmt: RETURN SEMICOLON {printf("return_stmt -> RETURN SEMICOLON\n");}
| RETURN add_exp SEMICOLON {printf("return_stmt -> RETURN add_exp SEMICOLON\n");}

when_stmt: WHEN L_PAREN add_exp R_PAREN LC stmts RC { printf("when_stmt -> WHEN L_PAREN exp R_PAREN LC stmts RC\n");}
| WHEN L_PAREN add_exp R_PAREN LC stmts RC ELSE LC stmts RC { printf("when_stmt -> WHEN L_PAREN exp R_PAREN LC stmts RC ELSE LC stmts RC\n");}
| WHEN L_PAREN add_exp R_PAREN LC stmts RC ELSE when_stmt { printf("when_stmt -> WHEN L_PAREN exp R_PAREN LC stmts RC ELSE when_stmt\n");}

whilst_stmt: WHILST exp LC stmt RC { printf("whilst_stmt -> WHILST exp LC stmt RC\n");}
| WHILST exp LC RC { printf("whilst_stmt -> WHILST exp LC RC\n");}

dowhilst_stmt: DO LC stmt RC WHILST exp { printf("dowhilst_stmt -> DO LC stmt RC WHILST exp\n");}
| DO LC RC WHILST exp { printf("dowhilst_stmt -> DO LC RC WHILST exp\n");}


function: type IDENTIFIER QM param_type_list QM LC stmts RC {printf("function -> type IDENTIFIER QM param_type_list QM LC stmts RC\n");}

function_call: IDENTIFIER QM param_list QM {printf("function_call -> IDENTIFIER QM add_exp QM\n");}

param_type_list: type IDENTIFIER COMMA param_type_list {printf("param_type_list -> type IDENTIFIER COMMA param_list\n");}
| type IDENTIFIER {printf("param_list -> type IDENTIFIER\n");}

param_list: add_exp COMMA {printf("param_list -> add_exp COMMA\n");}
| add_exp {printf("param_list -> add_exp\n");}
| {printf("param_list -> 'epsilon'\n");}

type: VOID {printf("type -> VOID\n");}
| INT {printf("type -> INT\n");}

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
