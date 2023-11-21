%{
#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <stdlib.h>

int yylex (void);

void yyerror (char const *err) { fprintf(stderr, "yyerror: %s\n", err); exit(-1); }

static char* genTempName() {
	static unsigned long long counter;
	static char buff[4096]; sprintf(buff, "temp%llu", counter++);
	return strdup(buff);
}

typedef struct { char **data; size_t len; } Vec;

static void VecPush(Vec *vec, char *cstring) {
	if ( !(vec->data = realloc(vec->data, sizeof(char *)*(vec->len + 1)))) {
		printf("bad_alloc\n"); exit(-1);
	}
	vec->data[vec->len++] = cstring;
}

static Vec vec;

%}

%define parse.error custom

%token NUM IDENTIFIER L_PAREN R_PAREN LC RC RB LB WHEN ELSE WHILST DO STOP READ WRITE VOID INT RETURN ASSIGN QM ESCAPE SEMICOLON COMMA

%left ADD SUB MUL DIV REL

%union {
   char* identifier;
}

%type<identifier> IDENTIFIER add_exp NUM exp REL rel_exp function_call mul_exp

%%

program: { printf("func main\n"); } stmts { printf("endfunc\n"); } {}

stmts: stmts stmt {}
|stmt {}

add_exp: mul_exp {
	$$ = $1;
}
| add_exp ADD add_exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("+ %s, %s, %s\n", name, $1, $3);
	$$ = name;
}
| add_exp SUB add_exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("- %s, %s, %s\n", name, $1, $3);
	$$ = name;
}

mul_exp: exp {
	$$ = $1;
}
| mul_exp MUL mul_exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("* %s, %s, %s\n", name, $1, $3);
	$$ = name;
}
| mul_exp DIV mul_exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("/ %s, %s, %s\n", name, $1, $3);
	$$ = name;
}

exp: NUM {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("= %s, %s\n", name, $1);
	$$ = $1;
}
| SUB exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("- %s, 0, %s\n", name, $2);
	$$ = name;
}
| L_PAREN add_exp R_PAREN {
	$$ = $2;
}
| rel_exp {
	$$ = $1;
}
| function_call {
	$$ = $1;
}
| IDENTIFIER {
	$$ = $1;
}
| IDENTIFIER LB add_exp RB {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("=[] %s, %s, %s\n", name, $1, $3);
	$$ = name;
}

rel_exp: exp REL exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("%s %s, %s, %s\n", $2, name, $1, $3);
}

stmt: assignment {}
| WRITE L_PAREN IDENTIFIER R_PAREN SEMICOLON {
	printf(".> %s\n", $3);
}
| READ L_PAREN IDENTIFIER R_PAREN SEMICOLON {
	printf(".< %s\n", $3);
}
| declaration {}
| when_stmt {}
| whilst_stmt {}
| dowhilst_stmt {}
| function {}
| return_stmt {}

return_stmt: RETURN SEMICOLON {
	printf("ret 0\n");
}
| RETURN add_exp SEMICOLON {
	printf("ret %s\n", $2);
}

when_stmt: WHEN L_PAREN add_exp R_PAREN LC stmts RC { }
| WHEN L_PAREN add_exp R_PAREN LC stmts RC ELSE LC stmts RC { }
| WHEN L_PAREN add_exp R_PAREN LC stmts RC ELSE when_stmt { }

whilst_stmt: WHILST L_PAREN add_exp R_PAREN LC stmts RC { }
| WHILST L_PAREN add_exp R_PAREN LC RC { }

dowhilst_stmt: DO LC stmts RC WHILST exp { }
| DO LC RC WHILST exp { }

function: type IDENTIFIER QM param_type_list { printf("func %s\n", $2); } QM LC stmts RC {
	printf("endfunc\n");
}

function_call: IDENTIFIER QM param_list QM {}

param_type_list: type IDENTIFIER COMMA param_type_list {}
| type IDENTIFIER LB RB COMMA param_type_list {}
| type IDENTIFIER {}
| type IDENTIFIER LB RB {}

param_list: add_exp COMMA {}
| add_exp {}
| {}

type: VOID {}
| INT {}

declaration: type IDENTIFIER SEMICOLON {
	printf(". %s\n", $2);
}
| type IDENTIFIER LB NUM RB SEMICOLON {
	printf(".[] %s, %s\n", $2, $4);
}

assignment: IDENTIFIER ASSIGN add_exp SEMICOLON {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("= %s, %s\n", name, $3);
}
| IDENTIFIER LB add_exp RB ASSIGN add_exp SEMICOLON {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("[]= %s, %s, %s\n", name, $3, $6);
}

%%

static int yyreport_syntax_error(const yypcontext_t *ctx) {
	yysymbol_kind_t tokenCausingError = yypcontext_token(ctx);
	yysymbol_kind_t expectedTokens[YYNTOKENS];
	int numExpectedTokens = yypcontext_expected_tokens(ctx, expectedTokens, YYNTOKENS);
	
	fprintf(stderr, "\n-- Syntax Error --\n");
	fprintf(stderr, "%llu line, %llu column\n", current_line, current_column);
	if (yysymbol_name(tokenCausingError) == "REL") {
		for (int i = 0; i < numExpectedTokens; i++) {
			if (yysymbol_name(expectedTokens[i]) == "ASSIGN") {
				printf("Assignment operator was expected. Found '=' instead\n");
			}
		}
	} else {
		fprintf(stderr, "Token causing error: %s\n", yysymbol_name(tokenCausingError));
		for (int i = 0; i < numExpectedTokens; ++i) {
			fprintf(stderr, " expected token (%d/%d): %s\n", i+1, numExpectedTokens, yysymbol_name(expectedTokens[i]));
		}
	}
	return 0;
}
