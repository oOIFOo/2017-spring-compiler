%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
%}
%token DIGIT
%token T_NODE
%token T_ENDLINE
%token T_COLON
%token T_SRIGHT
%token T_SLEFT
%token T_MLEFT
%token T_MRIGHT
%token T_PLUS
%token T_MINUS
%token T_STAR
%token T_semicolon
%token T_MOD
%token T_ASSIGN
%token T_LESS
%token T_LESSEQU
%token T_LB
%token T_BIGEUQ
%token T_LARGE
%token T_EQU
%token T_AND
%token T_OR
%token T_NOT
%token T_ARRAY
%token T_BEGIN
%token T_DEF
%token T_DO
%token T_ELSE
%token T_END
%token T_FLASE
%token T_FOR
%token T_INT
%token T_IF
%token T_OF
%token T_PRINT
%token T_READ
%token T_REAL
%token T_STRING
%token T_THEN
%token T_TO
%token T_TRUE
%token T_RETURN
%token T_WHILE
%token T_NEWLINE
%token T_VAR
%token T_BOOLEAN
%token T_NULL
%token T_DOUBLE

%token S_OCT
%token S_ID
%token S_INT
%token S_FLOAT
%token S_SCI
%token S_STRING

%left  T_PLUS T_MINUS
%left  T_STAR T_semicolon
%right T_EQU 

%start  PROGRAM
%%			
PROGRAM			:	S_ID T_ENDLINE DECLAR function COMPOUND function T_END S_ID {return;}
				;
				
function		:	S_ID T_SLEFT arguments T_SRIGHT T_COLON type T_ENDLINE COMPOUND T_END S_ID function1
				|	S_ID T_SLEFT arguments T_SRIGHT T_ENDLINE COMPOUND T_END S_ID function1
				|	function1
				;
				
function1		:	S_ID T_SLEFT arguments T_SRIGHT T_COLON type T_ENDLINE COMPOUND T_END S_ID function1
				|	S_ID T_SLEFT arguments T_SRIGHT T_ENDLINE COMPOUND T_END S_ID function1
				|
				;

DECLAR			:	T_VAR identifier_list T_COLON scalar_type T_ENDLINE DECLAR1 
				|	T_VAR identifier_list T_COLON T_ARRAY S_INT T_TO S_INT T_OF type T_ENDLINE DECLAR1
				|	T_VAR identifier_list T_COLON literal_constant DECLAR1
				|	DECLAR1 
				;
				
DECLAR1			:	T_VAR identifier_list T_COLON scalar_type T_ENDLINE DECLAR1
				|	T_VAR identifier_list T_COLON T_ARRAY S_INT T_TO S_INT T_OF type T_ENDLINE DECLAR1
				|   T_VAR identifier_list T_COLON literal_constant DECLAR1
				|	
				;
				
literal_constant:	S_INT
				|	S_ID
				|	T_FLASE
				|	T_TRUE
				|	S_OCT
				|	S_FLOAT
				|	S_SCI
				;
				
scalar_type		:	T_BOOLEAN
				|	T_INT
				| 	T_STRING
				|	T_REAL
				;	

BOOLEAN			:	T_TRUE
				|	T_FLASE
				;
				
statements 		: 	COMPOUND statements1
	
				|	T_WHILE boolean_expr T_DO statements T_END T_DO statements1
		
				|	T_FOR S_ID T_ASSIGN S_INT T_TO S_INT T_DO statements T_END T_DO statements1

				|	T_RETURN expression T_ENDLINE statements1

				|	T_IF boolean_expr T_THEN statements T_ELSE statements T_END T_IF statements1
				|	T_IF boolean_expr T_THEN statements T_END T_IF statements1

				|	variable_reference T_ASSIGN expression T_ENDLINE statements1
				|	T_PRINT variable_reference T_ENDLINE statements1
				| 	T_PRINT expression T_ENDLINE statements1
				| 	T_PRINT S_STRING T_ENDLINE statements1
				|	T_READ variable_reference T_ENDLINE statements1

				|	S_ID T_SLEFT expression T_SRIGHT statements1
				|	invocation statements1
				|	statements1
				;
				
statements1		:	COMPOUND statements1
	
				|	T_WHILE boolean_expr T_DO statements T_END T_DO statements1
		
				|	T_FOR S_ID T_ASSIGN S_INT T_TO S_INT T_DO statements T_END T_DO statements1

				|	T_RETURN expression T_ENDLINE statements1

				|	T_IF boolean_expr T_THEN statements T_ELSE statements T_END T_IF statements1
				|	T_IF boolean_expr T_THEN statements T_END T_IF statements1

				|	variable_reference T_ASSIGN expression T_ENDLINE statements1
				|	T_PRINT variable_reference T_ENDLINE statements1
				| 	T_PRINT expression T_ENDLINE statements1
				| 	T_PRINT S_STRING T_ENDLINE statements1
				|	T_READ variable_reference T_ENDLINE statements1

				|	S_ID T_SLEFT expression T_SRIGHT statements1
				|	invocation	statements1
				|
				;

invocation		:	S_ID T_SLEFT invocation_recur T_SRIGHT T_ENDLINE
				;
				
invocation_recur:	expression invocation_recur1
				|
				;
				
invocation_recur1:	T_NODE expression invocation_recur1
				|
				;
				
variable_reference:	S_ID T_MLEFT NUMBER T_MRIGHT VAR_RECUR
				|	S_ID
				;

VAR_RECUR		:	T_MLEFT NUMBER T_MRIGHT VAR_RECUR1
				|	VAR_RECUR1
				;
				
VAR_RECUR1		:	T_MLEFT NUMBER T_MRIGHT VAR_RECUR1
				|
				;

COMPOUND		:	T_BEGIN DECLAR statements T_END
				;
				
arguments		:	identifier_list T_COLON type arg_recur
				|	
				;
				
identifier_list :	S_ID ID_RECUR
				;
				
ID_RECUR		:	T_NODE S_ID ID_RECUR
				|	
				;

arg_recur		:	T_ENDLINE identifier_list T_COLON type arg_recur
				|
				;

type			:	T_BOOLEAN
				|	T_INT
				| 	T_STRING
				|
				;
				
expression		:	NUMBER OPERATOR NUMBER
				|	T_SLEFT T_MINUS NUMBER T_SRIGHT OPERATOR NUMBER
				|	T_SLEFT T_MINUS NUMBER T_SRIGHT OPERATOR T_SLEFT T_MINUS NUMBER T_SRIGHT
				|	NUMBER OPERATOR T_SLEFT T_MINUS NUMBER T_SRIGHT
				|	NUMBER
				;

boolean_expr	:	S_ID T_EQU BOOLEAN
				|	expression
				;
			
NUMBER			:	S_OCT
				|	S_INT
				|	S_FLOAT
				|	S_SCI
				|   S_ID
				;
				
OPERATOR		:	T_PLUS
				|	T_MINUS
				|	T_STAR
				|	T_semicolon
				|	T_MOD
				|	T_LESS
				|	T_LESSEQU
				|	T_LB
				|	T_BIGEUQ
				|	T_EQU
				|	T_LARGE
				|	T_AND
				|	T_OR
				|	T_NOT
				;
%%
int yyerror( char *msg )
{
    fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %d\n", (int)yytext[0] );
    fprintf( stderr, "|--------------------------------------------------------------------------\n" );
    exit(-1);
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
	
	yyin = fopen( argv[1], "r" );
	

	yyparse();

	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}

yywrap() {yyerror(buf); fclose(yyin); exit(1);}