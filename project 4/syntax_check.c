#include "syntax_check.h"

extern int linenum;		
extern FILE *yyin;		
extern char *yytext;	
extern char buf[256];
extern int yylex(void);
extern int scope;
extern char fileName[256];
extern struct SymTable *symbolTable;


void check_program(struct SymTable *table, char *msg){
	syntax_error = 0;
	struct SymNode *ptr;
	ptr = lookupSymbol(table, msg, 0, __TRUE);
	
	if(ptr == 0){
		syntax_error = 1;
	}
	else if(ptr->category == PROGRAM_t){
		if(strcmp(msg, ptr->name) | strcmp(fileName, ptr->name)){
			syntax_error = 1;
		}
	}
	
	if(syntax_error == 1)
		printf("<Error> found in Line #%d: program name '%s' should be '%s'\n", linenum, msg, fileName);
}

void check_function(struct SymTable *table, char *real_func_name, int opt, struct expr_sem oper1){
	struct SymNode *ptr, *tmp;
	syntax_error = 0;
	ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
	tmp = lookupSymbol(table, real_func_name, scope, __FALSE);				//check the real func name
	
	if(oper1.pType != 0){
		ptr->type = oper1.pType;
	}
	else if(oper1.varRef != 0) 
		ptr = lookupSymbol(table, oper1.varRef->id, scope, __FALSE);		//check the last same name
	
	if(ptr == 0){
		ptr->type = oper1.pType;
	}
		
	if(opt == 0) {								//check func return	
		//printf("**********%d**********\n", linenum);
		//printType(ptr->type ,0);
		if(ptr->type->type != tmp->type->type) {
			syntax_error = 2;
		}
		else if(tmp->type->isArray == 1 | ptr->type->isArray == 1){
			
			if(oper1.pType != 0)
				if(oper1.pType->isArray == 1)syntax_error = 2;
		}
	}
	
	if(syntax_error == 1) 
		printf("<Error> found in Line #%d: function end with wrong name\n", linenum);
	else if(syntax_error == 2) {
		if(tmp->type->isArray == 1 | ptr->type->isArray == 1)
			printf("<Error> found in Line #%d: function return array type \n", linenum);
		else
			printf("<Error> found in Line #%d: function return wrong type \n", linenum);
	}
}

void var_const_declar(struct SymTable *table, int opt, int lower, int upper){
	syntax_error = 0;
	if(opt == 1){
		if(lower > upper){
			syntax_error = 2;
		}
	}
	
	if(syntax_error == 2) 
		printf("<Error> found in Line #%d: array size declar wrong \n", linenum);
}

struct PType *var_references(struct SymTable *table, int opt, struct expr_sem oper1, struct expr_sem oper2){
	struct PType *type = (struct PType *)malloc( sizeof(struct PType) );
	type->isError = 0;
	struct SymNode *ptr = 0,*tmp = 0;
	struct SymNode *counter;
	syntax_error = 0;
	int flag = 0;
	
	if(oper2.pType != 0){
		if(oper2.pType->isError == 1) {
			tmp = (struct SymNode *)malloc( sizeof(struct SymNode) );
			tmp->type = oper2.pType;
			flag = 1;
		}
	}
	
	if(oper1.varRef != 0) 
		ptr = lookupSymbol(table, oper1.varRef->id, scope, __FALSE);
	if(ptr == 0) {
		ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
		ptr->type = oper1.pType;
	}
	
	counter = table->loopVar;
	while(counter != 0 && oper1.varRef != 0){
		if(!strcmp(counter->name, oper1.varRef->id)){
			ptr = counter;
			break;
		}
		else 
			counter = counter->next;
	}
		
	if(flag == 0){
		if(oper2.varRef != 0) 
			tmp = lookupSymbol(table, oper2.varRef->id, scope, __FALSE);
		if(tmp == 0) {
			tmp = (struct SymNode *)malloc( sizeof(struct SymNode) );
			tmp->type = oper2.pType;
		}
	}
	
	if(oper1.pType == 0 && ptr->type == 0){										//check LHS is exist
		type->isError = 1;
		printf("<Error> found in Line #%d: LHS do not exist \n", linenum);
		opt = -1;
	}
	if(oper2.pType == 0 && tmp->type == 0){										//check RHS is exist
		type->isError = 1;
		printf("<Error> found in Line #%d: RHS do not exist \n", linenum);
		opt = -1;
	}
	
	if(opt == 0){
		if(ptr->category == CONSTANT_t | ptr->category == LOOPVAR_t) {
			syntax_error = 1;
		}
		else if(ptr->type->type != tmp->type->type){								//check assignment type
			if(ptr->type->type == REAL_t && tmp->type->type == INTEGER_t);		
			else syntax_error = 1;
		}
		else if(tmp->type->isError == 1){
			syntax_error = 1;
		}
	}
	else if(opt == 1){
		if(ptr->type->type != INTEGER_t && ptr->type->type != REAL_t){		//check operation type	
			syntax_error = 2;
			type->isError = 1;
		}
		else if(tmp->type->type != INTEGER_t && tmp->type->type != REAL_t){
			syntax_error = 2;
			type->isError = 1;
		}
		else {
			type = type_convert(table, oper1, oper2);
		}
	}
	
	else if(opt == 3){		
		if(ptr->type->type != INTEGER_t | tmp->type->type != INTEGER_t){	//check mod operation
			syntax_error = 3;
			type->isError = 1;
		}
		else type->type = INTEGER_t;
	}
	
	else if(opt == 4){
		if(ptr->type->type != BOOLEAN_t | tmp->type->type != BOOLEAN_t){	//check boolean operation
			syntax_error = 4;
			type->isError = 1;
		}
		else type->type = BOOLEAN_t;
	}
	
	else if(opt == 5){
		if(ptr->type->type != INTEGER_t && ptr->type->type != REAL_t){		//check relation operation
			syntax_error = 5;
			type->isError = 1;
		}
		else if(tmp->type->type != INTEGER_t && tmp->type->type != REAL_t){
			syntax_error = 5;
			type->isError = 1;
		}
		else type->type = BOOLEAN_t;
	}
	
	if(opt >= 0){														 	//check whether is array type
		if(ptr->type->isArray == 1){
			if(oper1.pType != 0)
				if(oper1.pType->isArray == 1){
					syntax_error = 1;
					type->isError = 1;
				}
		}
		else if(tmp->type->isArray == 1){
			if(oper2.pType != 0)
				if(oper2.pType->isArray == 1){
					syntax_error = 1;
					type->isError = 1;
				}
		}
	}
	
	if(opt < 0)
		return type;
	
	if(syntax_error == 1){
		if(tmp->type->isError == 1)
			printf("<Error> found in Line #%d: RHS is error type \n", linenum);
		else if(ptr->category == CONSTANT_t)
			printf("<Error> found in Line #%d: assigment to constant type \n", linenum);
		else if(ptr->category == LOOPVAR_t)
			printf("<Error> found in Line #%d: assigment to counter type \n", linenum);
		else if(ptr->type->isArray == 1 | tmp->type->isArray == 1)
			printf("<Error> found in Line #%d: assigment between array type \n", linenum);
		else 
			printf("<Error> found in Line #%d: assigment between wrong type \n", linenum);
	}
	else if(syntax_error == 2) 
		printf("<Error> found in Line #%d: operation with wrong type \n", linenum);
	else if(syntax_error == 3) 
		printf("<Error> found in Line #%d: mod with wrong type \n", linenum);
	else if(syntax_error == 4) 
		printf("<Error> found in Line #%d: boolean with wrong type \n", linenum);
	else if(syntax_error == 5) 
		printf("<Error> found in Line #%d: relation operation with wrong type \n", linenum);
	
	return type;
}

struct PType *type_convert(struct SymTable *table, struct expr_sem oper1, struct expr_sem oper2){
	struct PType *type = (struct PType *)malloc( sizeof(struct PType) );
	type->isError = 0;
	struct SymNode *ptr = 0,*tmp = 0;
	
	if(oper1.varRef != 0) 
		ptr = lookupSymbol(table, oper1.varRef->id, scope, __FALSE);
	if(oper2.varRef != 0) 
		tmp = lookupSymbol(table, oper2.varRef->id, scope, __FALSE);
	
	if(ptr == 0) {
		ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
		ptr->type = oper1.pType;
	}
	if(tmp == 0) {
		tmp = (struct SymNode *)malloc( sizeof(struct SymNode) );
		tmp->type = oper2.pType;
	}
	
	if(ptr->type->isError == 1 | tmp->type->isError == 1){
		type->isError = 1;
	}
	else if(ptr->type->type == STRING_t | tmp->type->type == STRING_t){
		if(ptr->type->type == tmp->type->type) type->type = STRING_t;
	}
	else if(ptr->type->type == REAL_t | tmp->type->type == REAL_t){
		type->type = REAL_t;
	}
	else{
		type->type = ptr->type->type;
	}
	return type;
}

void verifyFuncInvoke( struct SymTable *table, char *name, struct expr_sem *oper1, int scope ){
	struct SymNode *ptr = 0;
	struct SymNode *tmp = 0;
	struct PTypeList *pTypePtr;
	syntax_error = 1;
	
	ptr = lookupSymbol(table, name, scope, __FALSE);				//check the real func name
	
	int i = 0;
	if(oper1 != 0){
		for( i=0, pTypePtr=(ptr->attribute->formalParam->params) ; i<(ptr->attribute->formalParam->paramNum) ; i++, pTypePtr=(pTypePtr->next) ){
			if(oper1->pType->type != pTypePtr->value->type){
				/*printf("\n++++++++++++%d+++++++++++\n", i);
				printType(oper1->pType ,0);
				printf("\n++++++++++++%d+++++++++++\n", i);
				printType(pTypePtr->value ,0);
				printf("\n++++++++++++%d+++++++++++\n", i);*/
				
				i = 0;
				break;
			}
			else{
				/*printf("\n-----------%d----------\n", i);
				printType(oper1->pType ,0);
				printf("\n-----------%d----------\n", i);*/
				
				if(oper1->next != 0){
					if(i == (ptr->attribute->formalParam->paramNum) - 1) {
						i = 0;
						break;
					}
					oper1 = oper1->next;
				}
				else
					break;
			}
		}
	}
	
	//printf("\n++++%d++++++++%d+++++++++++\n", i, ptr->attribute->formalParam->paramNum);
	if(i == (ptr->attribute->formalParam->paramNum)-1)
		syntax_error = 0;
	else if(oper1 == 0 && (ptr->attribute->formalParam->paramNum) == 0)
		syntax_error = 0;
	
	if(syntax_error == 1)
		printf("<Error> found in Line #%d: function call with wrong parameter \n", linenum);
}