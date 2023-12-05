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
typedef struct { int *data; size_t len; } VecInt;

static void VecPush(Vec *vec, char *cstring) {
	if ( !(vec->data = realloc(vec->data, sizeof(char *)*(vec->len + 1)))) {
		printf("bad_alloc\n"); exit(-1);
	}
	vec->data[vec->len++] = cstring;
}

static void VecIntPush(VecInt *vec, int num) {
	if ( !(vec->data = realloc(vec->data, sizeof(int)*(vec->len + 1)))) {
		printf("bad_alloc\n"); exit(-1);
	}
	vec->data[vec->len++] = num;
}

static Vec vec;
static Vec arrayVec;
static Vec vecFunc;
static VecInt vecSize;

int variableExists(char *var) {
	for (int i = 0; i < vec.len; ++i) {
		if (0 == strcmp(vec.data[i], var)) {
			return 1;
		}
	}
	return 0;
}

int arrayExists(char *var) 
{
	for (int i = 0; i < arrayVec.len; ++i) {
		if (0 == strcmp(arrayVec.data[i], var)) {
			return 1;
		}
	}
	return 0;
}


int functionExists(char *var) {
	for (int i = 0; i < vecFunc.len; ++i)
	{
		if (0 == strcmp(vecFunc.data[i], var))
		{
			return 1;
		}
	}
	return 0;
}

int outOfBoundsCheck(char *var, int index)
{
	for (int i = 0; i < arrayVec.len; ++i) {
		if (0 == strcmp(arrayVec.data[i], var)) {
			if (index >= vecSize.data[i])
			{
				return 1;
			}
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
   int paramCount;
}

%type<identifier> IDENTIFIER add_exp NUM exp REL rel_exp function_call mul_exp 

%type<control_flow> when_head whilst_stmt whilst_head whilst_body

%type<paramCount> param_type_list

%%

program: stmts {}

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
	else if (arrayExists($1)) {
		printSemanticError();
		fprintf(stderr, "Usage of array '%s', missing index value.\n", $1);
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
	else if (!arrayExists($1)) {
		printSemanticError();
		fprintf(stderr, "Usage of undefined array '%s'.\n", $1);
		exit(-1);
	}
	else if (outOfBoundsCheck($1, atoi($3)))
	{
		fprintf(stderr, "Out of bounds, array '%s'.\n", $1);
		exit(-1);
	}


	char* name = genTempName();
	printf(". %s\n", name);
	printf("=[] %s, %s, %s\n", name, $1, $3);
	$$ = name;
}

rel_exp: exp REL exp {
	char* name = genTempName();
	char* op = $2;
	if (!strcmp("=", op)) {
		op = "==";
	}
	printf(". %s\n", name);
	printf("%s %s, %s, %s\n", op, name, $1, $3);
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
| function_call SEMICOLON {}

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
	
whilst_stmt: whilst_head whilst_body LC stmts RC{
	printf(":= %s\n", $1.l1);					//goto beginlabel
	printf(": %s\n", $2.l1);					//print endlabel
}

whilst_head: WHILST{
	$$.l1 = genLabelName(0);					//beginLabel
	printf(": %s\n", $$.l1);					//print begin lable name
}

whilst_body: L_PAREN add_exp R_PAREN{
	char* name = genTempName();
	$$.l1 = genLabelName(0);					//endlabel
	printf(". %s\n", name);						//print temp for add_exp
	printf("! %s, %s\n", name, $2);				//compare 
	printf("?:= %s, %s\n", $$.l1, name);		//if true goto endlabel
}

dowhilst_stmt: DO LC stmts RC WHILST exp { }
| DO LC RC WHILST exp { }

function: type IDENTIFIER {
  VecPush(&vecFunc, $2);
	VecPush(&vec, $2);
	printf("func %s\n", $2);
} QM param_type_list QM LC stmts RC {
		printf("endfunc\n");
}

function_call: IDENTIFIER QM param_list QM {
	if (!functionExists($1))
	{
		fprintf(stderr, "Function '%s' not defined. \n", $1);
	}
  char* name = genTempName();
	printf(". %s\n", name);
	printf("call %s, %s\n", $1, name);
	$$ = name;
}

param_type_list: type IDENTIFIER COMMA param_type_list {
	VecPush(&vec, $2);
	printf(". %s\n", $2);
	printf("= %s, $%i\n", $2, $4 + 1);
	$$ = $4 + 1;
}
| type IDENTIFIER LB RB COMMA param_type_list {
	VecPush(&vec, $2);
	printf("= %s, $%i\n", $2, $6 + 1);
	$$ = $6 + 1;
}
| type IDENTIFIER {
	VecPush(&vec, $2);
	printf(". %s\n", $2);
	printf("= %s, $%i\n", $2, 0);
	$$ = 0;
}
| type IDENTIFIER LB RB {
	VecPush(&vec, $2);
	printf("= %s, $%i\n", $2, 0);
	$$ = 0;
}
| {}

param_list: add_exp COMMA param_list {
	printf("param %s\n", $1);
}
| add_exp {
	printf("param %s\n", $1);
}
| {}

type: VOID {}
| INT {}

declaration: type IDENTIFIER SEMICOLON {
	if (variableExists($2)) {
		printSemanticError();
		fprintf(stderr, "Variable '%s' already defined in scope. \n", $2);
		exit(-1);
	}
	VecPush(&vec, $2);
	printf(". %s\n", $2);
}
| type IDENTIFIER LB NUM RB SEMICOLON {
	if (variableExists($2)) {
		printSemanticError();
		fprintf(stderr, "Variable '%s' already defined in scope. \n", $2);
		exit(-1);
	}

	if (atoi($4) <= 0) {
		printSemanticError();
		fprintf(stderr, "Array size must be greater than zero!\n");
		exit(-1);
	}

	VecPush(&vec, $2);
	VecIntPush(&vecSize, atoi($4));
	VecPush(&arrayVec, $2);
	printf(".[] %s, %s\n", $2, $4);
}

assignment: IDENTIFIER ASSIGN add_exp SEMICOLON {
	if (arrayExists($1)) {
		printSemanticError();
		fprintf(stderr, "Usage of array '%s', missing index value.\n", $1);
		exit(-1);
	}
	else if (!variableExists($1)) {
		printSemanticError();
		fprintf(stderr, "Undefined variable '%s'\n", $1);
		exit(-1);
	}
	printf("= %s, %s\n", $1, $3);
}

| IDENTIFIER LB add_exp RB ASSIGN add_exp SEMICOLON {
	if (!arrayExists($1)) {
		printSemanticError();
		fprintf(stderr, "Usage of undefined array '%s'.\n", $1);
		exit(-1);
	}
	else if (outOfBoundsCheck($1, atoi($3)))
	{
		fprintf(stderr, "Out of bounds, array '%s'.\n", $1);
		exit(-1);
	}
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
