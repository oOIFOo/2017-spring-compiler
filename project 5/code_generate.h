#ifndef _CODE_GENERATE_h
#define _CODE_GENERATE_h
#include "header.h"
#include "symtab.h"
#include "semcheck.h"
void global_inintial(int opt, char *name);
void staticvar(struct SymTable *table);
void func_init(struct SymTable *table, char *name, struct param_sem *parameter);
void func_end(struct SymTable *table, char *name);
struct SymNode *push_var(struct SymNode *in_node);
void pop_var(char *name);
void LHS_access(struct SymTable *table, struct expr_sem oper1, struct expr_sem oper2, int opt);
void print_code(struct SymTable *table, struct expr_sem oper);
int RHS_gen(struct SymTable *table, struct expr_sem oper);
void read_code(struct SymTable *table, struct expr_sem oper);
void gen_boolean(struct SymTable *table, struct expr_sem oper1, struct expr_sem oper2, OPERATOR opt);
void gen_if(struct expr_sem oper, int opt);
void gen_for(struct SymTable *table, char *name, int low_bound, int up_bound, int opt);
void return_gen(struct SymTable *table, struct expr_sem oper);
void gen_while(struct SymTable *table, struct expr_sem oper, int opt);
#endif