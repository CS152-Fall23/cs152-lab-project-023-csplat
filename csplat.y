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

static char* genLabelName(int offset) {
	static unsigned long long counter;
	static char buff[4096];
	
	switch(offset) {
		case 0: { sprintf(buff, "label%llu", counter++);} break;
		default: { sprintf(buff, "label%llu", counter + offset);} break;
	}

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

int variableExists(char *var) {
	for (int i = 0; i < vec.len; ++i) {
		if (0 == strcmp(vec.data[i], var)) {
			return 1;
		}
	}
	return 0;
}

void printSemanticError() {
	fprintf(stderr, "Error line %llu: ", current_line);
}

%}

%define parse.error custom

%token NUM IDENTIFIER L_PAREN R_PAREN LC RC RB LB WHEN ELSE WHILST DO STOP READ WRITE VOID INT RETURN ASSIGN QM ESCAPE SEMICOLON COMMA

%left ADD SUB MUL DIV REL

%union {
   char* identifier;
   struct {
	char* l1;
   	char* l2;
   	char* l3;
   } control_flow;
}

%type<identifier> IDENTIFIER add_exp NUM exp REL rel_exp function_call mul_exp 

%type<control_flow> when_head whilst_stmt whilst_head

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
	$$ = name;
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
	if (!variableExists($1)) {
		printSemanticError();
		fprintf(stderr, "Undefined variable '%s'\n", $1);
		exit(-1);
	}
	$$ = $1;
}
| IDENTIFIER LB add_exp RB {
	if (!variableExists($1)) {
		printSemanticError();
		fprintf(stderr, "Undefined variable '%s'\n", $1);
		exit(-1);
	}
	char* name = genTempName();
	printf(". %s\n", name);
	printf("=[] %s, %s, %s\n", name, $1, $3);
	$$ = name;
}

rel_exp: exp REL exp {
	char* name = genTempName();
	printf(". %s\n", name);
	printf("%s %s, %s, %s\n", $2, name, $1, $3);
	$$ = name;
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

when_stmt: when_head LC stmts RC {
	printf(":= %s\n", $1.l1);
} ELSE {
	printf(": %s\n", $1.l2);
} LC stmts RC {
	printf(": %s\n", $1.l1);
}
| when_head LC stmts RC {
	printf(": %s\n", $1.l2);
}

when_head: WHEN L_PAREN add_exp R_PAREN {
	char* name = genTempName();
	$$.l1 = genLabelName(0);
	$$.l2 = genLabelName(0);
	printf(". %s\n", name);
	printf("! %s, %s\n", name, $3);
	printf("?:= %s, %s\n", $$.l2, name);
}

whilst_stmt: whilst_head LC stmts RC {
	printf("?:= %s\n", $1.l1);			//goto beginlabel
	printf(": %s\n", $1.l2);			//endlabel
}
whilst_head: WHILST L_PAREN add_exp R_PAREN{
	char* name = genTempName();
	$$.l1 = genLabelName(0);					//beginLabel
	$$.l2 = genLabelName(0);					//endlabel
	printf(": %s\n", $$.l1);					//print begin lable name
	printf(". %s\n", name);						//print temp for add_exp
	printf("! %s, %s\n", name, $3);				//compare 
	printf("?:= %s, %s\n", $$.l2, name);		//if true goto endlabel
}

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
	VecPush(&vec, $2);
	printf(". %s\n", $2);
}
| type IDENTIFIER LB NUM RB SEMICOLON {
	VecPush(&vec, $2);
	if (atoi($4) <= 0) {
		printSemanticError();
		fprintf(stderr, "Array size must be greater than zero!\n");
		exit(-1);
	}
	printf(".[] %s, %s\n", $2, $4);
}

assignment: IDENTIFIER ASSIGN add_exp SEMICOLON {
	printf("= %s, %s\n", $1, $3);
}
| IDENTIFIER LB add_exp RB ASSIGN add_exp SEMICOLON {
	printf("[]= %s, %s, %s\n", $1, $3, $6);
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
