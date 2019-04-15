#ifndef _SYNTAX_CHECK_H_
#define _SYNTAX_CHECK_H_
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"

int yydebug;
int yyerror(char* );
int syntax_error;
int dim_counter;
char *func_name;
struct SymNode return_type;
struct ConstAttr assign_type;

void check_program(struct SymTable *table, char *msg);
void check_function(struct SymTable *table, char *real_func_name, int opt, struct expr_sem oper1);
void var_const_declar(struct SymTable *table, int opt, int lower, int upper);
struct PType *var_references(struct SymTable *table, int opt, struct expr_sem oper1, struct expr_sem oper2);
struct PType *type_convert(struct SymTable *table, struct expr_sem oper1, struct expr_sem oper2);
void verifyFuncInvoke( struct SymTable *table, char *name, struct expr_sem *oper1, int scope );
#endif