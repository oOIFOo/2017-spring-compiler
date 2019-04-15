#include "code_generate.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
struct local{
	char *name;
	int num;
	struct SymNode *node;
};

extern char fileName[256];
extern int if_id;
char file_name[40];
extern FILE *out_file;
struct local var_stack[100];
extern int j_index;

void global_inintial(int opt, char *name){
	char tmp[40];
	strcpy(file_name, name);
	strcpy(tmp, name);
	strcat(tmp,".j");
	
	if(opt == 0){
		out_file = fopen(tmp, "w");
		fprintf(out_file, ".class public %s\n", name);
		fprintf(out_file, ".super java/lang/Object\n");
	}
	else if(opt == 1){
		fprintf(out_file, ".method public static main([Ljava/lang/String;)V\n");
		fprintf(out_file, ".limit stack 100\n");
		fprintf(out_file, ".limit locals 100\n");
		fprintf(out_file, "new java/util/Scanner\n");
		fprintf(out_file, "dup\n");
		fprintf(out_file, "getstatic java/lang/System/in Ljava/io/InputStream;\n");
		fprintf(out_file, "invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
		fprintf(out_file, "putstatic %s/_sc Ljava/util/Scanner;\n", name);
	}
	else if(opt == 2){
		fprintf(out_file, "return\n");
		fprintf(out_file, ".end method");
	}
}

void staticvar(struct SymTable *table){
	struct SymNode *ptr;
	
	fprintf(out_file,".field public static _sc Ljava/util/Scanner;\n"); 
	for (int i = 0; i < HASHBUNCH; i++)
	{
		for (ptr = (table->entry[i]); ptr != 0; ptr = (ptr->next))
		{
			switch (ptr->type->type)
			{
			case INTEGER_t:
				fprintf(out_file, ".field public static %s ", ptr->name);
				fprintf(out_file, "I\n");
				break;
			case REAL_t:
				fprintf(out_file, ".field public static %s ", ptr->name);
				fprintf(out_file, "F\n");
				break;
			case BOOLEAN_t:
				fprintf(out_file, ".field public static %s ", ptr->name);
				fprintf(out_file, "Z\n");
				break;
			case STRING_t:
				//sprintf(buffer, "string");
				break;
			case VOID_t:
				//sprintf(buffer, "void");
				break;
			default:
				/* FIXME */
				break;
			}
		}
	}
}

struct SymNode *push_var(struct SymNode *in_node){
	struct SymNode *newnode;
	if(in_node->scope != 0){
		while (1){
			var_stack[j_index].node = (struct SymNode *)malloc( sizeof(struct SymNode) );
			var_stack[j_index].node->name = in_node->name;
			var_stack[j_index].node->category = in_node->category;
			var_stack[j_index].node->type = in_node->type;
			var_stack[j_index].node->attribute = in_node->attribute;
			var_stack[j_index].node->next = in_node->next;
			var_stack[j_index].node->prev = in_node->prev;
			var_stack[j_index].num = j_index;
			in_node->stack_id = j_index;
			j_index++;
	
			if(in_node->next != NULL) in_node = in_node->next;
			else break;
		}
	}
	
	return in_node;
}

void pop_var(char *name){
	for(int i = 0;i < j_index;i++){
		if(name == var_stack[j_index].name){
			var_stack[j_index].name = "0";
			break;
		}
	}
}

void func_init(struct SymTable *table, char *name, struct param_sem *parameter){
	int i, num = 0;
	struct PTypeList *index = 0;
	struct SymNode *ptr = 0;
	ptr = lookupSymbol(table, name, 0, __FALSE);
	
	fprintf(out_file, ".method public static %s(", name);
	
	index = ptr->attribute->formalParam->params;
	
	//printf("++++++++++%s+++++++++\n", index->idlist->value);
	while(index != NULL){
		if(index->value->type == INTEGER_t)
			fprintf(out_file, "I");
		else if(index->value->type == REAL_t)
			fprintf(out_file, "F");
		else if(index->value->type == BOOLEAN_t)
			fprintf(out_file, "Z");
		
		if(index->next == NULL)
			break;
		
		index = index->next;
	}
	
	if(ptr->type->type == INTEGER_t)
		fprintf(out_file, ")I\n");
	else if(ptr->type->type == REAL_t)
		fprintf(out_file, ")F\n");
	else if(ptr->type->type == BOOLEAN_t)
		fprintf(out_file, ")Z\n");
	else 
		fprintf(out_file, ")V\n");
	
	fprintf(out_file, ".limit stack 100\n");
	fprintf(out_file, ".limit locals 100\n");
}

void func_end(struct SymTable *table, char *name){
	struct SymNode *ptr = 0;
	ptr = lookupSymbol(table, name, 0, __FALSE);
	
	if(ptr->type->type == INTEGER_t | ptr->type->type == BOOLEAN_t)
		fprintf(out_file, "ireturn\n");
	else if(ptr->type->type == REAL_t)
		fprintf(out_file, "freturn\n");
	else
		fprintf(out_file, "return\n");
	
	fprintf(out_file, ".end method\n");
}

void return_gen(struct SymTable *table, struct expr_sem oper){
	int flag = RHS_gen(table, oper);
	if(flag == 0){
		fprintf(out_file, "ireturn\n");
	}
	else if(flag == 1){
		fprintf(out_file, "freturn\n");
	}
}

void LHS_access(struct SymTable *table, struct expr_sem oper1, struct expr_sem oper2, int opt){
	struct SymNode *ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
	ptr = lookupSymbol(table, oper1.varRef->id, 10, __FALSE);
	
	int flag = RHS_gen(table, oper2);
	if(ptr->type->type == INTEGER_t | ptr->type->type == BOOLEAN_t){
		fprintf(out_file, "istore %d\n",  ptr->stack_id);
	}
	else{
		if(flag == 0) fprintf(out_file, "i2f\n");
		fprintf(out_file, "fstore %d\n", ptr->stack_id);
	}
}

int RHS_gen(struct SymTable *table, struct expr_sem oper){
	int flag = 0;
	int neg_flag = 0;
	int not_flag = 0;
	struct SymNode *ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
	struct SymNode *tmp = 0;
	if(oper.varRef != 0){
		ptr = lookupSymbol(table, oper.varRef->id, 10, __FALSE);
		if(ptr == NULL)
			ptr = lookupLoopVar(table, oper.varRef->id);
		
		if(ptr->category == CONSTANT_t)
			oper.attr = ptr->attribute->constVal;
	}
	else if(oper.pType != 0){
		ptr->type = oper.pType;
		ptr->category = CONSTANT_t;
		
		if(oper.id != NULL)
			ptr = lookupSymbol(table, oper.id, 10, __FALSE);
	}
	
	if(oper.beginningOp == SUB_t){
		if(ptr->type->type == INTEGER_t){
			neg_flag = 1;
		}
		else if(ptr->type->type == REAL_t){
			neg_flag = 2;
		}
	}
	else if(oper.beginningOp == NOT_t){
		not_flag = 1;
	}
	
	if(ptr->category == CONSTANT_t){
		if(ptr->type->type == INTEGER_t){
			fprintf(out_file, "ldc %d\n", oper.attr->value.integerVal);
		}
		else if(ptr->type->type == REAL_t){
			flag = 1;
			fprintf(out_file, "ldc %f\n", oper.attr->value.realVal);
		}
		else if(ptr->type->type == STRING_t){
			fprintf(out_file, "ldc \"%s\"\n", oper.attr->value.stringVal);
		}
		else if(ptr->type->type == BOOLEAN_t){
			if(oper.attr->value.booleanVal == __TRUE)
				fprintf(out_file, "iconst_1\n");
			else if(oper.attr->value.booleanVal == __FALSE)
				fprintf(out_file, "iconst_0\n");
		}
	}
	else if(ptr->category == FUNCTION_t){
		/*struct PTypeList *index =  (struct PTypeList *)malloc( sizeof(struct PTypeList) );
		if(ptr->attribute != NULL)
			index = ptr->attribute->formalParam->params;
		
		struct expr_sem *func_oper = 0;
		func_oper = oper.next;
		
		if(func_oper != NULL){
			RHS_gen(table,*func_oper);
		
			for(func_oper = func_oper;func_oper != NULL;func_oper = func_oper->next);
			
			if(func_oper->comma != NULL)
				RHS_gen(table,*func_oper->comma);
		}
		
		
		fprintf(out_file, "invokestatic test5/ %s(", oper.id);

		/*while(index != NULL){
			if(index->value->type == INTEGER_t)
				fprintf(out_file, "I");
			else if(index->value->type == REAL_t)
				fprintf(out_file, "F");
			else if(index->value->type == BOOLEAN_t)
				fprintf(out_file, "Z");
			
			if(index->next == NULL)
				break;
			
			index = index->next;
		}
	
		if(ptr->type->type == INTEGER_t)
			fprintf(out_file, ")I\n");
		else if(ptr->type->type == REAL_t)
			fprintf(out_file, ")F\n");
		else if(ptr->type->type == BOOLEAN_t)
			fprintf(out_file, ")Z\n");
		else 
			fprintf(out_file, ")V\n");*/
	}
	else{
		printf("*****%s*****\n", ptr->name);
		if(ptr->type->type == INTEGER_t){
			if(ptr->scope == 0){
				fprintf(out_file,"getstatic %s/%s I\n",fileName,ptr->name);
				printf("*****%s*****\n", ptr->name);
			}
			else
				fprintf(out_file, "iload %d\n", ptr->stack_id);
		}
		else if(ptr->type->type == REAL_t){
			flag = 1;
			if(ptr->scope == 0)
				fprintf(out_file,"getstatic %s/%s F\n",fileName,ptr->name);
			else
				fprintf(out_file, "fload %d\n", ptr->stack_id);
		}
		else if(ptr->type->type == BOOLEAN_t){
			if(ptr->scope == 0)
				fprintf(out_file,"getstatic %s/%s Z\n",fileName,ptr->name);
			else
				fprintf(out_file, "iload %d\n", ptr->stack_id);
		}
	}

	if(ptr->category != CONSTANT_t){
		if(neg_flag == 1){
			fprintf(out_file, "ineg\n");
			neg_flag = 0;
		}
		else if(neg_flag == 2){
			fprintf(out_file, "fneg\n");
			neg_flag = 0;
		}
	}
	
	if(not_flag == 1){
		fprintf(out_file, "ixor\n");
		not_flag = 0;
	}

	while(oper.next != NULL){	
		oper = *oper.next;
		if(oper.varRef != 0){
			tmp = lookupSymbol(table, oper.varRef->id, 10, __FALSE);
			if(tmp == NULL)
				tmp = lookupLoopVar(table, oper.varRef->id);
			
			if(tmp->category == CONSTANT_t)
				oper.attr = tmp->attribute->constVal;
		}
		else if(oper.pType != 0){
			tmp = (struct SymNode *)malloc( sizeof(struct SymNode) );
			tmp->type = oper.pType;
			tmp->category = CONSTANT_t;
			
			if(oper.id != NULL)
				tmp = lookupSymbol(table, oper.id, 10, __FALSE);
		}
		
		if(oper.beginningOp == NOT_t){
			not_flag = 1;
		}
		
		if(tmp->category == CONSTANT_t){
			if(tmp->type->type == INTEGER_t){
				fprintf(out_file, "ldc %d\n", oper.attr->value.integerVal);
			}
			else if(tmp->type->type == REAL_t){
				fprintf(out_file, "ldc %f\n", oper.attr->value.realVal);
			}
			else if(tmp->type->type == STRING_t){
				fprintf(out_file, "ldc \"%s\"\n", oper.attr->value.stringVal);
			}
			else if(tmp->type->type == BOOLEAN_t){
				if(oper.attr->value.booleanVal == __TRUE)
					fprintf(out_file, "iconst_1\n");
				else if(oper.attr->value.booleanVal == __FALSE)
					fprintf(out_file, "iconst_0\n");
			}
		}
		else if(tmp->category == FUNCTION_t){
		}
		else{
			if(tmp->type->type == INTEGER_t){
				if(ptr->scope == 0)
					fprintf(out_file,"getstatic %s/%s I\n",fileName,ptr->name);
				else
					fprintf(out_file, "iload %d\n", tmp->stack_id);
			}
			else if(tmp->type->type == REAL_t){
				if(ptr->scope == 0)
					fprintf(out_file,"getstatic %s/%s F\n",fileName,ptr->name);
				else
					fprintf(out_file, "fload %d\n", tmp->stack_id);
			}
			else if(tmp->type->type == BOOLEAN_t){
				if(ptr->scope == 0)
					fprintf(out_file,"getstatic %s/%s Z\n",fileName,ptr->name);
				else	
					fprintf(out_file, "iload %d\n", tmp->stack_id);
			}
		}

		if(ptr->type->type != tmp->type->type){
			flag = 1;
			if(oper.pType->type == REAL_t){
				fprintf(out_file, "fstore %d\n", j_index);
				fprintf(out_file, "i2f\n");
				fprintf(out_file, "fload %d\n", j_index);
			}
			else
				fprintf(out_file, "i2f\n");
			
			tmp->type->type = REAL_t;
		}
		
		if(not_flag == 1){
			fprintf(out_file, "ixor\n");
			not_flag = 0;
		}
		
		
		if(ptr->type->type == INTEGER_t && tmp->type->type == INTEGER_t){
			flag = 0;
			if(oper.beginningOp == ADD_t){
				fprintf(out_file, "iadd\n");
			}
			else if(oper.beginningOp == SUB_t){
				fprintf(out_file, "isub\n");
			}
			else if(oper.beginningOp == MUL_t){
				fprintf(out_file, "imul\n");
			}
			else if(oper.beginningOp == DIV_t){
				fprintf(out_file, "idiv\n");
			}
			else if(oper.beginningOp == MOD_t){
				fprintf(out_file, "irem\n");
			}
		}
		else if(ptr->type->type == BOOLEAN_t && tmp->type->type == BOOLEAN_t){
			if(oper.beginningOp == AND_t){
				fprintf(out_file, "iand\n");
			}
			else if(oper.beginningOp == OR_t){
				fprintf(out_file, "ior\n");
			}
			else if(oper.beginningOp == NOT_t){
				fprintf(out_file, "ixor\n");
			}
		}
		else{
			flag = 1;
			if(oper.beginningOp == ADD_t){
				fprintf(out_file, "fadd\n");
			}
			else if(oper.beginningOp == SUB_t){
				fprintf(out_file, "fsub\n");
			}
			else if(oper.beginningOp == MUL_t){
				fprintf(out_file, "fmul\n");
			}
			else if(oper.beginningOp == DIV_t){
				fprintf(out_file, "fdiv\n");
			}
		}
		
		if(oper.neg_flag == 1){
			if(flag == 0)
				fprintf(out_file, "ineg\n");
			else if(flag == 1)
				fprintf(out_file, "fneg\n");
		}

		if(oper.next == NULL)
			break;
		else 
			ptr = tmp;
	}
	
	return flag;
}

void print_code(struct SymTable *table, struct expr_sem oper){
	fprintf(out_file, "getstatic java/lang/System/out Ljava/io/PrintStream;\n");
	
	struct SymNode *ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
	if(oper.varRef != 0){
		ptr = lookupSymbol(table, oper.varRef->id, 10, __FALSE);
		
		if(ptr == NULL)
			ptr = lookupLoopVar(table, oper.varRef->id);
	}
	else if(oper.pType != 0){
		ptr->type = oper.pType;
		ptr->category = CONSTANT_t;
	}
	
	int flag;
	flag = RHS_gen(table, oper);
		
	if(ptr->category == CONSTANT_t && ptr->type->type == STRING_t){
		fprintf(out_file, "invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
	}
	else if(ptr->category == FUNCTION_t){
	}
	else{
		if(ptr->type->type == INTEGER_t && flag == 0){
			fprintf(out_file, "invokevirtual java/io/PrintStream/print(I)V\n");
		}
		else if(ptr->type->type == STRING_t){
			fprintf(out_file, "invokevirtual java/io/PrintStream/print(F)V\n");
		}
		else if(ptr->type->type == BOOLEAN_t){
			fprintf(out_file, "invokevirtual java/io/PrintStream/print(Z)V\n");
		}
		else{
			fprintf(out_file, "invokevirtual java/io/PrintStream/print(F)V\n");
		}
	}
}

void read_code(struct SymTable *table, struct expr_sem oper){
	struct SymNode *tmp = (struct SymNode *)malloc( sizeof(struct SymNode) );
	tmp = lookupSymbol(table, oper.varRef->id, 10, __FALSE);
	
	fprintf(out_file, "getstatic %s/_sc Ljava/util/Scanner;\n", file_name);
	
	if(tmp->type->type == INTEGER_t){
		fprintf(out_file, "invokevirtual java/util/Scanner/nextInt()I\n");
		fprintf(out_file, "istore %d\n", tmp->stack_id);
	}
	else if(tmp->type->type == REAL_t){
		fprintf(out_file, "invokevirtual java/util/Scanner/nextFloat()F\n");
		fprintf(out_file, "fstore %d\n", tmp->stack_id);
	}
	else if(tmp->type->type == BOOLEAN_t){
		fprintf(out_file, "invokevirtual java/util/Scanner/nextBoolean()Z\n");
		fprintf(out_file, "istore %d\n", tmp->stack_id);
	}
}

void gen_boolean(struct SymTable *table, struct expr_sem oper1, struct expr_sem oper2, OPERATOR opt){
	struct SymNode *ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
	struct SymNode *tmp = (struct SymNode *)malloc( sizeof(struct SymNode) );
	if(oper1.varRef != 0){
		ptr = lookupSymbol(table, oper1.varRef->id, 10, __FALSE);
		if(ptr == NULL)
			ptr = lookupLoopVar(table, oper1.varRef->id);
		
		if(ptr->category == CONSTANT_t)
			oper1.attr = ptr->attribute->constVal;
	}
	else if(oper1.pType != 0){
		ptr->type = oper1.pType;
		ptr->category = CONSTANT_t;
		
		if(oper1.id != NULL)
			ptr = lookupSymbol(table, oper1.id, 10, __FALSE);
	}
	
	if(oper2.varRef != 0){
		tmp = lookupSymbol(table, oper2.varRef->id, 10, __FALSE);
		if(tmp == NULL)
			tmp = lookupLoopVar(table, oper2.varRef->id);
		
		if(tmp->category == CONSTANT_t)
			oper2.attr = tmp->attribute->constVal;
	}
	else if(oper2.pType != 0){
		tmp->type = oper2.pType;
		tmp->category = CONSTANT_t;
		
		if(oper2.id != NULL)
			tmp = lookupSymbol(table, oper2.id, 10, __FALSE);
	}
	
	if(ptr->category == CONSTANT_t){
		if(ptr->type->type == INTEGER_t){
			fprintf(out_file, "ldc %d\n", oper1.attr->value.integerVal);
		}
		else if(ptr->type->type == REAL_t){
			fprintf(out_file, "ldc %f\n", oper1.attr->value.realVal);
		}
		else if(ptr->type->type == STRING_t){
			fprintf(out_file, "ldc \"%s\"\n", oper1.attr->value.stringVal);
		}
	}
	else{
		if(ptr->type->type == INTEGER_t | ptr->type->type == BOOLEAN_t){
			fprintf(out_file, "iload %d\n", ptr->stack_id);
		}
		else{
			fprintf(out_file, "fload %d\n", ptr->stack_id);
		}
	}
	
	if(tmp->category == CONSTANT_t){
		if(tmp->type->type == INTEGER_t){
			fprintf(out_file, "ldc %d\n", oper2.attr->value.integerVal);
		}
		else if(tmp->type->type == REAL_t){
			fprintf(out_file, "ldc %f\n", oper2.attr->value.realVal);
		}
		else if(tmp->type->type == STRING_t){
			fprintf(out_file, "ldc \"%s\"\n", oper2.attr->value.stringVal);
		}
	}
	else{
		if(tmp->type->type == INTEGER_t | tmp->type->type == BOOLEAN_t){
			fprintf(out_file, "iload %d\n", tmp->stack_id);
		}
		else{
			fprintf(out_file, "fload %d\n", tmp->stack_id);
		}
	}
	
	if(ptr->type->type == INTEGER_t && tmp->type->type == INTEGER_t)
		fprintf(out_file, "isub\n");
	else
		fprintf(out_file, "fsub\n");
}

void gen_if(struct expr_sem oper, int opt){
	if(opt == 0){
		if(oper.beginningOp == LT_t){
			fprintf(out_file, "iflt Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == LE_t){
			fprintf(out_file, "ifle Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == EQ_t){
			fprintf(out_file, "ifeq Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == GE_t){
			fprintf(out_file, "ifge Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == GT_t){
			fprintf(out_file, "ifgt Ltrue_%d\n",if_id);
		}

		fprintf(out_file, "iconst_0\n");
		fprintf(out_file, "goto Lfalse_%d\n",if_id);
		fprintf(out_file, "Ltrue_%d:\n",if_id);
		fprintf(out_file, "iconst_1\n");
		fprintf(out_file, "Lfalse_%d:\n",if_id);

		if_id++;
		
		fprintf(out_file, "ifeq Lelse_%d\n",if_id);
	}
	else if(opt == 1){
		fprintf(out_file, "goto Lexit_%d\n",if_id);
		fprintf(out_file, "Lelse_%d:\n",if_id);
		if_id++;
	}
	else if(opt == 2){
		if_id--;
		fprintf(out_file, "Lexit_%d:\n",if_id);
		if_id--;
	}
}

void gen_for(struct SymTable *table, char *name, int low_bound, int up_bound, int opt){
	struct SymNode *ptr = (struct SymNode *)malloc( sizeof(struct SymNode) );
	ptr = lookupLoopVar(table, name);
	
	if(opt == 0){
		fprintf(out_file, "ldc %d\n", low_bound);
		fprintf(out_file, "istore %d\n", ptr->stack_id);
		fprintf(out_file, "Lbegin_%d:\n", if_id);
		if_id++;
		
		fprintf(out_file, "iload %d\n", ptr->stack_id);
		fprintf(out_file, "ldc %d\n", up_bound);
		fprintf(out_file, "isub\n");
		fprintf(out_file, "ifle Ltrue_%d\n", if_id);
		fprintf(out_file, "iconst_0\n");
		fprintf(out_file, "goto Lfalse_%d\n", if_id);
		fprintf(out_file, "Ltrue_%d:\n", if_id);
		fprintf(out_file, "iconst_1\n");
		fprintf(out_file, "Lfalse_%d:\n", if_id);
		fprintf(out_file, "ifeq Lexit_%d\n", if_id-1);
		if_id++;
	}
	else if(opt == 1){
		fprintf(out_file, "iload %d\n", ptr->stack_id);
		fprintf(out_file, "sipush 1\n");
		fprintf(out_file, "iadd\n");
		fprintf(out_file, "istore %d\n", ptr->stack_id);
		
		if_id -= 2;
		fprintf(out_file, "goto Lbegin_%d\n", if_id);
		fprintf(out_file, "Lexit_%d:\n", if_id);
	}
}

void gen_while(struct SymTable *table, struct expr_sem oper, int opt){
	if(opt == 0){
		if_id++;
		if(oper.beginningOp == LT_t){
			fprintf(out_file, "iflt Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == LE_t){
			fprintf(out_file, "ifle Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == EQ_t){
			fprintf(out_file, "ifeq Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == GE_t){
			fprintf(out_file, "ifge Ltrue_%d\n",if_id);
		}
		else if(oper.beginningOp == GT_t){
			fprintf(out_file, "ifgt Ltrue_%d\n",if_id);
		}
		fprintf(out_file, "iconst_0\n");
		fprintf(out_file, "goto Lfalse_%d\n", if_id);
		fprintf(out_file, "Ltrue_%d:\n", if_id);
		fprintf(out_file, "iconst_1\n");
		fprintf(out_file, "Lfalse_%d:\n", if_id);
		fprintf(out_file, "ifeq Lexit_%d\n", if_id-1);
		if_id++;
	}
	else if(opt == 1){
		if_id -= 2;
		fprintf(out_file, "goto Lbegin_%d\n", if_id);
		fprintf(out_file, "Lexit_%d:\n", if_id);
	}
}
