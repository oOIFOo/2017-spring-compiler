%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 2 YACC sample
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct symboltable{
	char name[100];
	char *kind;
	int  level;
	char type[32];
	char attribute[32];
}mysymbol;

typedef struct tokentable{
	char name[32];
	int  flag;
}mytoken;

int pow(int a,int b);
void push(mysymbol input);
void pop();
void dumpsymbol();
int checkredeclar(char* in);
void dumperror(char* in);
void itoa(int in);
long long convertOctalToDecimal(int octalNumber);
float  scitodec(char *in);

int			oct;
float 		sci;
int 		level_in = 0;
int 		stack_size = -1;
int			id_index = -1;
int			flag_index = -1;
int			flag_redeclar = -1;
int			array_start = -1;
int			array_end = -1;
mysymbol 	stack[100];
mytoken 	id_stack[100];
char		array_size[100];
char		type_name[100];
char		type_tmp[32];
char		attr_tmp[32];
char		sci_attr_tmp[32];
char		error_tmp[32];

extern int linenum;		/* declared in lex.l */
extern FILE *yyin;		/* declared by lex */
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern int yylex(void);
extern char *in_tmp;
extern int Opt_D;

mysymbol tmp;
mysymbol func_tmp;
int yyerror(char* );

%}
/* tokens */
%token ARRAY
%token BEG
%token BOOLEAN
%token DEF
%token DO
%token ELSE
%token END
%token FALSE
%token FOR
%token INTEGER
%token IF
%token OF
%token PRINT
%token READ
%token REAL
%token RETURN
%token STRING
%token THEN
%token TO
%token TRUE
%token VAR
%token WHILE

%token ID
%token OCTAL_CONST
%token INT_CONST
%token FLOAT_CONST
%token SCIENTIFIC
%token STR_CONST

%token OP_ADD
%token OP_SUB
%token OP_MUL
%token OP_DIV
%token OP_MOD
%token OP_ASSIGN
%token OP_EQ
%token OP_NE
%token OP_GT
%token OP_LT
%token OP_GE
%token OP_LE
%token OP_AND
%token OP_OR
%token OP_NOT

%token MK_COMMA
%token MK_COLON
%token MK_SEMICOLON
%token MK_LPAREN
%token MK_RPAREN
%token MK_LB
%token MK_RB

/* start symbol */
%start program
%%

program				:ID {	
							strcpy(tmp.name,yytext);
							tmp.kind = "program";
							tmp.level = level_in;
							strcpy(tmp.type, "void");
							strcpy(tmp.attribute, " ");
							push(tmp);
						}
					  MK_SEMICOLON program_body END{if(Opt_D)dumpsymbol();} ID{printf("%d: %s\n",  linenum,  buf);return 1;}
					;

program_body		: opt_decl_list opt_func_decl_list compound_stmt 
					;

opt_decl_list		: decl_list
					| /* epsilon */
					;

decl_list			: decl_list decl
					| decl
					;

decl				: VAR id_list MK_COLON scalar_type 
						{
							while(id_index >= 0){
								strcpy(tmp.name ,id_stack[id_index].name);
								tmp.kind = "variable";
								tmp.level = level_in;
								strcpy(tmp.type, type_name);
								strcpy(tmp.attribute, "");
								push(tmp);
								id_index--;
							}
						}MK_SEMICOLON   
						
					| VAR id_list MK_COLON {strcpy(type_tmp, "");}array_type 
						{
							while(id_index >= 0){
								strcpy(tmp.name ,id_stack[id_index].name);
								tmp.kind = "variable";
								tmp.level = level_in;
								strcpy(tmp.type, type_name);
								strcpy(tmp.attribute, "");
								push(tmp);
								id_index--;
							}
						}MK_SEMICOLON        /* array type declaration */
						
					| VAR id_list MK_COLON literal_const 
						{
							strcpy(tmp.type, "");
							strcpy(tmp.attribute, "");
							while(id_index >= 0){
								strcpy(tmp.name ,id_stack[id_index].name);
								tmp.kind = "constant";
								tmp.level = level_in;
								strcpy(tmp.type, type_name);
								strcpy(tmp.attribute, attr_tmp);
								push(tmp);
								id_index--;
							}
							strcpy(tmp.attribute, "");
						}MK_SEMICOLON     /* const declaration */
					;
					
int_const			:	INT_CONST {strcpy(type_name, "integer");strcpy(attr_tmp, yytext);}
					|	OCTAL_CONST {oct = atoi(yytext);oct = convertOctalToDecimal(oct);snprintf(attr_tmp,32, "%d", oct);}
					;

literal_const		: int_const 			
					| OP_SUB int_const		{strcpy(type_name, "integer");strcpy(attr_tmp, "-");strcat(attr_tmp, yytext);}
					| FLOAT_CONST 			{strcpy(type_name, "real");strcpy(attr_tmp, yytext);strcat(attr_tmp, "0000");}
					| OP_SUB FLOAT_CONST 	{strcpy(type_name, "real");strcpy(attr_tmp, "-");strcat(attr_tmp, yytext);strcat(attr_tmp, "0000");}
					| SCIENTIFIC 			{strcpy(type_name, "real");sci = scitodec(yytext);snprintf(attr_tmp,32, "%f", sci);}
					| OP_SUB SCIENTIFIC 	{strcpy(type_name, "real");strcpy(attr_tmp, "-");sci = scitodec(yytext);
											snprintf(sci_attr_tmp,32, "%f", sci);strcat(attr_tmp, sci_attr_tmp);}
					| STR_CONST 			{strcpy(type_name, "string");strcpy(attr_tmp, yytext);}
					| TRUE 					{strcpy(type_name, "boolean");strcpy(attr_tmp, yytext);}
					| FALSE 				{strcpy(type_name, "boolean");strcpy(attr_tmp, yytext);}
					;

opt_func_decl_list	: func_decl_list
					| /* epsilon */
					;

func_decl_list		: func_decl_list func_decl
					| func_decl
					;

func_decl			: 	ID{	strcpy(func_tmp.name, yytext);
							func_tmp.level = level_in;
							func_tmp.kind = "function";
							strcpy(func_tmp.attribute, "");
						} 
						MK_LPAREN{level_in++;} opt_param_list MK_RPAREN{level_in--;} 
						opt_type {
									strcpy(func_tmp.type, type_name);
								}
						MK_SEMICOLON compound_stmt END {}ID {push(func_tmp);}
					;

opt_param_list		: param_list
					| /* epsilon */
					;

param_list			: param_list MK_SEMICOLON {strcat(func_tmp.attribute, "  ");}param
					| param
					;

param				: id_list MK_COLON type	
						{
							while(id_index >= 0){
								strcpy(tmp.name ,id_stack[id_index].name);
								tmp.kind = "parameter";
								tmp.level = level_in;
								strcpy(tmp.type, type_name);
								strcat(func_tmp.attribute, type_name);
								strcat(func_tmp.attribute, "  ");
								push(tmp);
								id_index--;
							}
						}
					;

id_list				: 	id_list MK_COMMA ID 
						{	
							if(Opt_D){
								flag_redeclar = checkredeclar(yytext);
								if(flag_redeclar){
									id_index++;
									strcpy(id_stack[id_index].name,yytext);
									id_stack[id_index].name[32] = '\0';
								}
								else {dumperror(yytext);}
							}
						}
					| ID{
							if(Opt_D){
								flag_redeclar = checkredeclar(yytext);
								if(flag_redeclar){
									id_index++;strcpy(id_stack[id_index].name,yytext);
									id_stack[id_index].name[32] = '\0';
								}
								else {dumperror(yytext);}
							}
						}
					;

opt_type			: MK_COLON {strcpy(type_tmp, "");} type
					| /* epsilon */ {strcpy(type_name, "void");}
					;

type				: scalar_type 
					| array_type  {}
					;
	
scalar_type			: INTEGER 	{strcpy(type_name, "integer");}
					| REAL		{strcpy(type_name, "real");}
					| BOOLEAN	{strcpy(type_name, "boolean");}
					| STRING	{strcpy(type_name, "string");}
					;

array_type			: 	ARRAY int_const {	
											array_start = atoi(yytext);
										}
						TO int_const {	array_end = atoi(yytext);
										array_end = array_end - array_start + 1;
										snprintf(array_size,100, "%d", array_end);
										strcat(type_tmp, "[");
										strcat(type_tmp, array_size);
										
										strcat(type_tmp, "]");
									}
						OF type {
									strcpy(type_name, yytext);
									strcat(type_name, type_tmp);
								}
					;

stmt				: compound_stmt
					| simple_stmt
					| cond_stmt
					| while_stmt
					| for_stmt
					| return_stmt
					| proc_call_stmt
					;

compound_stmt		: BEG {level_in++;} opt_decl_list  opt_stmt_list  END{if(Opt_D)dumpsymbol();level_in--;}
					;

opt_stmt_list		: stmt_list
					| /* epsilon */
					;

stmt_list			: stmt_list stmt
					| stmt
					;

simple_stmt			: var_ref OP_ASSIGN boolean_expr MK_SEMICOLON
					| PRINT boolean_expr MK_SEMICOLON
					| READ boolean_expr MK_SEMICOLON
					;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
					;

cond_stmt			: IF boolean_expr THEN  opt_stmt_list  ELSE  opt_stmt_list  END IF
					| IF boolean_expr THEN opt_stmt_list END IF
					;

while_stmt			: WHILE boolean_expr DO  opt_stmt_list  END DO
					;

for_stmt			: FOR ID {
								flag_redeclar = checkredeclar(yytext);
								if(flag_redeclar){
									strcpy(tmp.name ,yytext);
									tmp.level = level_in + 1;
									tmp.kind = "counter";
									push(tmp);
								}
								else{dumperror(yytext);}
							}		
					  OP_ASSIGN int_const TO int_const DO  opt_stmt_list  END DO {if( stack[stack_size].kind == "counter")pop();}
					;

return_stmt			: RETURN boolean_expr MK_SEMICOLON
					;

opt_boolean_expr_list	: boolean_expr_list
						| /* epsilon */
						;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
					| boolean_expr
					;

boolean_expr		: boolean_expr OP_OR boolean_term
					| boolean_term
					;

boolean_term		: boolean_term OP_AND boolean_factor
					| boolean_factor
					;

boolean_factor		: OP_NOT boolean_factor 
					| relop_expr
					;

relop_expr			: expr rel_op expr
					| expr
					;

rel_op				: OP_LT
					| OP_LE
					| OP_EQ
					| OP_GE
					| OP_GT
					| OP_NE
					;

expr				: expr add_op term
					| term
					;

add_op				: OP_ADD
					| OP_SUB
					;

term				: term mul_op factor
					| factor
					;

mul_op				: OP_MUL
					| OP_DIV
					| OP_MOD
					;

factor				: var_ref
					| OP_SUB var_ref
					| MK_LPAREN boolean_expr MK_RPAREN
					| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
					| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
					| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
					| literal_const
					;

var_ref				: ID
					| var_ref dim
					;

dim					: MK_LB boolean_expr MK_RB
					;

%%

int yyerror( char *msg )
{
	(void) msg;
	fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
	fprintf( stderr, "|--------------------------------------------------------------------------\n" );
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );

	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();	/* primary procedure of parser */
	exit(0);
}

void push(mysymbol input){	
	stack_size++;
	stack[stack_size] = input; 
	return;
}

void pop(){
	stack_size--; 
	return;
}

void dumpsymbol(){
	int pre_stack = stack[stack_size].level;
	int i;
    for(i=0;i< 110;i++) {
        printf("=");
    }
	printf("\n");
	printf("%-33s%-11s%-11s%-17s%-11s\n","Name","Kind","Level","Type","Attribute");
	for(i=0;i< 110;i++) {
        printf("-");
    }
	printf("\n");
	while(stack[stack_size].level == level_in && stack_size >= 0 && stack[stack_size].kind != "counter"){
		printf("%-32s", stack[stack_size].name);
		printf("%-11s", stack[stack_size].kind);
		
		if(pre_stack == 0) printf("%d%-10s",stack[stack_size].level,"(global)");
		else  printf("%d%-10s",stack[stack_size].level,"(local)");
		
		printf("%-17s", stack[stack_size].type);
		printf("%-11s", stack[stack_size].attribute);
		printf("\n");
		pop();
	}
	for(i=0;i< 110;i++) {
        printf("-");
    }
	printf("\n");
	return;
}

int checkredeclar(char* in){
	int x = 0;
	for(int j = stack_size;j >= 0 && level_in == stack[j].level; j--){
		for(int i = 0;i < 31;i++){
			if(in[i] != stack[j].name[i]) x = 1;
		}
		if(strcmp(in,stack[j].name) == 0) x = 0;
		if(x == 0) return 0;
		x = 0;
	}
	return 1;
}

void dumperror(char* in){
	char tmp[32];
	snprintf(tmp,32, "%s", in);
	printf("<Error> found in Line %d: symbol %s redeclared\n", linenum,tmp );
	return;
}

long long convertOctalToDecimal(int octalNumber)
{
    int decimalNumber = 0, i = 0;

    while(octalNumber != 0)
    {
        decimalNumber += (octalNumber%10) * pow(8,i);
        ++i;
        octalNumber/=10;
    }

    i = 1;

    return decimalNumber;
}

int pow(int a,int b){
	int n=1; 
	for(int x=0;x<b;x++) n=n*a; 
	return n; 
}

float scitodec(char *in){
	char  tmp[32];
	float out = 0;
	int i = 0, x = 0, w = 10, plus = 0;
	int t = 0;
	strcpy(tmp, in);
	
	out = atoi(&tmp[i]);
	for(;tmp[i] != '.';i++);
	t = i + 1;
	for(;tmp[i] != 'e' && tmp[i] != 'E';i++);
	
	out *= pow(10, (i - t));
	out += atoi(&tmp[t]);
	out /= pow(10, (i - t));
	
	i++;
	if(tmp[i] == '+') plus = 1;
	else plus = 0;
	
	x = atoi(&tmp[i + 1]);
	while(x){
		if(plus) out *= 10;
		if(!plus) out /= 10;
		x--;
	}
	return out;
}
int yywrap(){return 0;}

