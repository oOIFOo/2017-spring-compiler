%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 3 YACC sample
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"
#include "syntax_check.h"

int yydebug;

extern int linenum;		/* declared in lex.l */
extern FILE *yyin;		/* declared by lex */
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern int yylex(void);
int yyerror(char* );

int scope = 0;

int Opt_D = 1;			/* symbol table dump option */
char fileName[256];


struct SymTable *symbolTable;	// main symbol table

__BOOLEAN paramError;			// indicate is parameter have any error?

struct PType *funcReturn;		// record function's return type, used at 'return statement' production rule
%}

%union {
	int intVal;
	float realVal;
	char *lexeme;
	struct idNode_sem *id;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	struct expr_sem_node *exprNode;
};

/* tokens */
%token ARRAY BEG BOOLEAN DEF DO ELSE END FALSE FOR INTEGER IF OF PRINT READ REAL RETURN STRING THEN TO TRUE VAR WHILE
%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD OP_ASSIGN OP_EQ OP_NE OP_GT OP_LT OP_GE OP_LE OP_AND OP_OR OP_NOT
%token MK_COMMA MK_COLON MK_SEMICOLON MK_LPAREN MK_RPAREN MK_LB MK_RB

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <realVal>FLOAT_CONST
%token <realVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<id> id_list
%type<constVal> literal_const
%type<ptype> type scalar_type array_type opt_type
%type<par> param param_list opt_param_list
%type<exprs> var_ref boolean_expr boolean_term boolean_factor relop_expr expr term factor boolean_expr_list opt_boolean_expr_list condition_while
%type<intVal> dim mul_op add_op rel_op array_index loop_param

/* start symbol */
%start program
%%

program			: ID
			{
			  struct PType *pType = createPType( VOID_t );
			  struct SymNode *newNode = createProgramNode( $1, scope, pType );
			  insertTab( symbolTable, newNode );
			}
			  MK_SEMICOLON 
			  program_body
			  END ID
			{
			  if( Opt_D == 1 )
				printSymTable( symbolTable, scope );
			  check_program(symbolTable, yytext);
			}
			;

program_body		: opt_decl_list opt_func_decl_list compound_stmt
			;

opt_decl_list		: decl_list
			| /* epsilon */
			;

decl_list		: decl_list decl
			| decl
			;

decl			: VAR id_list MK_COLON scalar_type MK_SEMICOLON       /* scalar type declaration */
			{
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					insertTab( symbolTable, newNode );
				}
			  }

			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
			{
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( $4->isError == __TRUE ) { }
				else if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					insertTab( symbolTable, newNode );
				}
			  }

			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
			{
			  struct PType *pType = createPType( $4->category );
			  // insert constants into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createConstNode( ptr->value, scope, pType, $4 );
					insertTab( symbolTable, newNode );
				}
			  }
			  
			  deleteIdList( $2 );
			}
			;

literal_const		: INT_CONST
			{
			  int tmp = $1;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			}
			| OP_SUB INT_CONST
			{
			  int tmp = -$2;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			}
			| FLOAT_CONST
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| OP_SUB FLOAT_CONST
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| SCIENTIFIC
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| OP_SUB SCIENTIFIC
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| STR_CONST
			{
			  $$ = createConstAttr( STRING_t, $1 );
			}
			| TRUE
			{
			  __BOOLEAN tmp = __TRUE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			}
			| FALSE
			{
			  __BOOLEAN tmp = __FALSE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			}
			;

opt_func_decl_list	: func_decl_list
			| /* epsilon */
			;

func_decl_list		: func_decl_list func_decl
			| func_decl
			;

func_decl	: ID
			MK_LPAREN opt_param_list
			{
			  // check and insert parameters into symbol table
			  func_name = $1;
			  paramError = insertParamIntoSymTable( symbolTable, $3, scope+1 );
			}
			  MK_RPAREN opt_type 
			{
			  // check and insert function into symbol table
			  insertFuncIntoSymTable( symbolTable, $1, $3, $6, scope );
			  funcReturn = $6;
			  if($6 -> isArray == 1) printf("<Error> found in Line #%d: function can not return array type \n", linenum);
			}
			  MK_SEMICOLON
			  compound_stmt
			  END ID
			{
			  if(strcmp(yytext, func_name))
				printf("<Error> found in Line #%d: function end with wrong name\n", linenum);
				
			  funcReturn = 0;
			}
			;

opt_param_list		: param_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }
			;

param_list		: param_list MK_SEMICOLON param
			{
			  param_sem_addParam( $1, $3 );
			  $$ = $1;
			}
			| param { $$ = $1; }
			;

param			: id_list MK_COLON type { $$ = createParam( $1, $3 ); }
			;

id_list			: id_list MK_COMMA ID
			{
			  idlist_addNode( $1, $3 );
			  $$ = $1;
			}
			| ID { $$ = createIdList($1); }
			;

opt_type		: MK_COLON type { $$ = $2; }
			| /* epsilon */ { $$ = createPType( VOID_t ); }
			;

type			: scalar_type { $$ = $1; }
			| array_type { $$ = $1; }
			;

scalar_type		: INTEGER { $$ = createPType( INTEGER_t ); }
			| REAL { $$ = createPType( REAL_t ); }
			| BOOLEAN { $$ = createPType( BOOLEAN_t ); }
			| STRING { $$ = createPType( STRING_t ); }
			;

array_type		: ARRAY array_index TO array_index OF type
			{
				var_const_declar(symbolTable, 1, $2, $4);
				increaseArrayDim( $6, $2, $4 );
				$$ = $6;
			}
			;

array_index		: INT_CONST { $$ = $1; }
			;

stmt			: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

compound_stmt		: 
			{ 
			  scope++;
			}
			  BEG
			  opt_decl_list
			  opt_stmt_list
			  END 
			{ 
			  // print contents of current scope
			  if( Opt_D == 1 )
			  	printSymTable( symbolTable, scope );
			  deleteScope( symbolTable, scope );	// leave this scope, delete...
			  scope--; 
			}
			;

opt_stmt_list		: stmt_list
			| /* epsilon */
			;

stmt_list		: stmt_list stmt
			| stmt
			;

simple_stmt		: var_ref OP_ASSIGN boolean_expr MK_SEMICOLON
			{
				var_references(symbolTable, 0, *$1, *$3);
			}
			| PRINT boolean_expr MK_SEMICOLON 
			{
				if($2->pType->isArray == 1) printf("<Error> found in Line #%d: print wrong symbol \n", linenum);
			}
 			| READ boolean_expr MK_SEMICOLON 
			{
				if($2->pType->isArray == 1) printf("<Error> found in Line #%d: read wrong symbol \n", linenum);
			}
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			{
			  verifyFuncInvoke( symbolTable, $1, $3, scope );
			}
			;

cond_stmt		: IF condition THEN
			  opt_stmt_list
			  ELSE
			  opt_stmt_list
			  END IF
			| IF condition THEN opt_stmt_list END IF
			;

condition		: boolean_expr
			;

while_stmt	: WHILE condition_while DO 
			{
				if($2->pType == 0) printf("<Error> found in Line #%d: while with wrong condition \n", linenum);
				else if($2->pType->type != BOOLEAN_t) 
					printf("<Error> found in Line #%d: while with wrong condition \n", linenum);
			}
			opt_stmt_list
			END DO
			;

condition_while		: boolean_expr {$$ = $1;}
			;

for_stmt		: FOR ID
			{
			  insertLoopVarIntoTable( symbolTable, $2 );
			}
			  OP_ASSIGN loop_param TO loop_param
			  DO 
			  {
				if($5 > $7) printf("<Error> found in Line #%d: for with wrong condition \n", linenum);
			  }
			  opt_stmt_list
			  END DO
			{
			  popLoopVar( symbolTable );
			}
			;

loop_param		: INT_CONST { $$ = $1; }
			| OP_SUB INT_CONST { $$ = -$2; }
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
				{
					check_function(symbolTable, func_name, 0, *$2);
				}
			;

opt_boolean_expr_list	: boolean_expr_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }	// null
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
			{
			  struct expr_sem *exprPtr;
			  for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  exprPtr->next = $3;
			  $$ = $1;
			}
			| boolean_expr
			{
			  $$ = $1;
			}
			;

boolean_expr		: boolean_expr OP_OR boolean_term
			{
			  if($1->pType->type != BOOLEAN_t | $3->pType->type != BOOLEAN_t){
				  printf("<Error> found in Line #%d: boolean with wrong type \n", linenum);
				  $1->pType->isError = 1;
			  }
			  else 
				   $1->pType->type = BOOLEAN_t;
			  
			  $$ = $1;
			}
			| boolean_term { $$ = $1; }
			;

boolean_term		: boolean_term OP_AND boolean_factor
			{ 	 
			  if($1->pType->type != BOOLEAN_t | $3->pType->type != BOOLEAN_t){
				  printf("<Error> found in Line #%d: boolean with wrong type \n", linenum);
				  $1->pType->isError = 1;
			  }
			  else 
				   $1->pType->type = BOOLEAN_t;
				   
			  $$ = $1;
			}
			| boolean_factor { $$ = $1;}
			;

boolean_factor		: OP_NOT boolean_factor 
			{
			  if($2->pType->type != BOOLEAN_t){
				  printf("<Error> found in Line #%d: boolean with wrong type \n", linenum);
				  $2->pType->isError = 1;
			  }
			  else 
				  $2->pType->type = BOOLEAN_t;
				   
			  $$ = $2;
			}
			| relop_expr { $$ = $1;}
			;

relop_expr		: expr rel_op expr
			{
			  $$ = $1;
			  $$->pType = var_references(symbolTable, 5, *$1, *$3);
			  
			}
			| expr { $$ = $1; }
			;

rel_op		: OP_LT { $$ = LT_t; }
			| OP_LE { $$ = LE_t; }
			| OP_EQ { $$ = EQ_t; }
			| OP_GE { $$ = GE_t; }
			| OP_GT { $$ = GT_t; }
			| OP_NE { $$ = NE_t; }
			;

expr		: expr add_op term
			{
			  $$ = $1;
			  if($2 == ADD_t){
				if($1->pType->type == STRING_t && $3->pType->type == STRING_t){
					$$->pType->type = STRING_t;
				}
				else $$->pType = var_references(symbolTable, 1, *$1, *$3);
			  }
			  else $$->pType = var_references(symbolTable, 1, *$1, *$3);
			}
			| term { $$ = $1; }
			;

add_op			: OP_ADD { $$ = ADD_t; }
			| OP_SUB { $$ = SUB_t; }
			;

term		: term mul_op factor
			{
			  $$ = $1;
			  if($2 == MOD_t) $$->pType = var_references(symbolTable, 3, *$1, *$3);
			  else $$->pType = var_references(symbolTable, 1, *$1, *$3);
			}
			| factor { $$ = $1; }
			;

mul_op		: OP_MUL { $$ = MUL_t; }
			| OP_DIV { $$ = DIV_t; }
			| OP_MOD { $$ = MOD_t; }
			;

factor		: var_ref
			{
			  $$ = $1;
			  $$->beginningOp = NONE_t;
			}
			| OP_SUB var_ref
			{
			  $$ = $2;
			  $$->beginningOp = SUB_t;
			}
			| MK_LPAREN boolean_expr MK_RPAREN 
			{
			  $2->beginningOp = NONE_t;
			  $$ = $2; 
			}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			{
			  $$ = $3;
			  $$->beginningOp = SUB_t;
			}
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
              $$->next = 0;

              struct SymNode *node = 0;
              node = lookupSymbol( symbolTable, $1, 0, __FALSE );

              $$->pType = node->type;
			  $$->beginningOp = NONE_t;
			}
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  //$$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
              $$->next = 0;

              struct SymNode *node = 0;
              node = lookupSymbol( symbolTable, $2, 0, __FALSE );

              $$->pType = node->type;
			  $$->beginningOp = SUB_t;
			}
			| literal_const
			{ 
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
			  $$->pType = createPType( $1->category );
			  $$->next = 0;
			  if( $1->hasMinus == __TRUE ) {
			  	$$->beginningOp = SUB_t;
			  }
			  else {
				$$->beginningOp = NONE_t;
			  }
			}
			;

var_ref			: ID
			{
				$$->stringVal = $1;
				
			    $$ = createExprSem( $1 );
				
				struct SymNode *tmp = 0;
			    tmp = lookupSymbol(symbolTable, $1, scope, __FALSE);
				if(tmp != 0)
					if(tmp->type->isArray == 1){
						$$->pType = (struct PType *)malloc( sizeof(struct PType) );
						$$->pType->isArray = 1;
					}
					else $$->pType = tmp->type;
			}
			| var_ref dim
			{
			  increaseDim( $1, $2 );
			  $$ = $1;
			  		  
			  dim_counter = $$->varRef->dimNum;
			  
			  struct SymNode *tmp = 0;
			  tmp = lookupSymbol(symbolTable, $1->varRef->id, scope, __FALSE);
			 
			  if(tmp != 0)
				  if(tmp->type != 0){
					  if(dim_counter == tmp->type->dimNum){
						  //printf("+++++++%d++++++++++%d\n", dim_counter, tmp->type->dimNum);
						  $$->pType = (struct PType *)malloc( sizeof(struct PType) );
						  $$->pType->type = tmp->type->type;
						  $$->pType->isArray = 0;
					  }
					  else{
						  $$->pType = (struct PType *)malloc( sizeof(struct PType) );
						  $$->pType->type = tmp->type->type;
						  //if(tmp->type->isArray == 1)
							$$->pType->isArray = 1;
					  }
				  }
			}
			;

dim			: MK_LB boolean_expr MK_RB
            {
              $$ = INTEGER_t;
            }
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
	exit(-1);
}