/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 1 Sample
 */

%{

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"

#define LIST strcat( buf, yytext )


#define  MAX_LINE_LENG  256

int Opt_S = 1;				/* list source code option */
int Opt_T = 1;				/* list token option */
int linenum = 1;			/* line number */
char buf[MAX_LINE_LENG];		/* source code line buffer */
char strContent[MAX_LINE_LENG];		/* string buffer */

void setPseudoComment( const char * );	/* pseudo comment option switch */
%}

whitespace [ \t]+
letter [A-Za-z]
digit [0-9]
integer 0|[1-9][0-9]*
octal 0[0-7]+
fraction 0|[0-9]*
float {integer}"."{fraction}
scientific ({integer}|{float}|{octal})[Ee][+-]?({integer}|{octal})
identifier ({letter})({letter}|{digit})*

 /* exclusive start conditions */
%x COMMENT
%x COMMENT_CPP

%%

","				{LIST; return T_NODE;}
";"				{LIST; return T_ENDLINE;}
":"				{LIST; return T_COLON;}
")"				{LIST; return T_SRIGHT;}
"("				{LIST; return T_SLEFT;}
"["				{LIST; return T_MLEFT;}
"]"				{LIST; return T_MRIGHT;}

"+"				{LIST; return T_PLUS;}
"-"				{LIST; return T_MINUS;}
"*"				{LIST; return T_STAR;}
"/"				{LIST; return T_semicolon;}
"mod"			{LIST; return T_MOD;}
":="			{LIST; return T_ASSIGN;}
"<"				{LIST; return T_LESS;}
"<="			{LIST; return T_LESSEQU;}
"<>"			{LIST; return T_LB;}
">="			{LIST; return T_BIGEUQ;}
">"				{LIST; return T_LARGE;}
"="				{LIST; return T_EQU;}
"and"			{LIST; return T_AND;}
"or"			{LIST; return T_OR;}
"not"			{LIST; return T_NOT;}

"array"			{LIST; return T_ARRAY;}
begin			{LIST; return T_BEGIN;}
"boolean"		{LIST; return T_BOOLEAN;}
"def"			{LIST; return T_DEF;}
"do"			{LIST; return T_DO;}
"else"			{LIST; return T_ELSE;}
"end"			{LIST; return T_END;}
"false"			{LIST; return T_FLASE;}
"for"			{LIST; return T_FOR;}
integer			{LIST; return T_INT;}
"if"			{LIST; return T_IF;}
"of"			{LIST; return T_OF;}
"print"			{LIST; return T_PRINT;}
"read"			{LIST; return T_READ;}
"real"			{LIST; return T_REAL;}
"string"		{LIST; return T_STRING;}
"then"			{LIST; return T_THEN;}
"to"			{LIST; return T_TO;}
"true"			{LIST; return T_TRUE;}
"return"		{LIST; return T_RETURN;}
"var"			{LIST; return T_VAR;}
"while"			{LIST; return T_WHILE;}

0[0-7]+							{LIST;return S_OCT;}
{letter}+({letter}|{digit})* 	{LIST;return S_ID;}
{digit}+[.]{digit}+				{LIST;return S_FLOAT;}
{digit}+						{LIST;return S_INT;}
{scientific}					{LIST;return S_SCI;}

\"((\"\")|[^\"\n])*\"	{
				LIST;
				if (Opt_T){
					size_t wrt_idx = 0;
					size_t rd_idx = 1;
					int quote = 0;
					while( yytext[rd_idx] ){
						if( yytext[rd_idx] == '\"' ){
							if( quote )
								strContent[wrt_idx++] = '\"';
							quote = ~quote;
						}
						else
							strContent[wrt_idx++] = yytext[rd_idx];
						rd_idx++;
					}
				}
				return S_STRING;
			}

"//&"[A-Z][+-][^\n]*		{ /* pseudo comment */
				  LIST;
				  setPseudoComment( yytext );
				}
"//"				{ /* C++ stype comment */
				  LIST;
				  BEGIN COMMENT_CPP;
				}

<COMMENT_CPP>[^\n]+		{
				  LIST;
				}

<COMMENT_CPP>"\n"		{
				  LIST;
				  if( Opt_S )
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
				  BEGIN INITIAL;
				}

"/*"				{ /* C-style comment */
				  LIST;
				  BEGIN COMMENT;
				}
<COMMENT>"*/"			{
				  LIST;
				  BEGIN INITIAL;
				}
<COMMENT>"\n"			{
				  LIST;
				  if  (Opt_S)
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
				}
<COMMENT>.			{
				  LIST;
				}

{whitespace}			{ 
				  LIST; 
				}

"\n" 			{
				  LIST;
				  if  (Opt_S)
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
		   		}

"\r"			{}
				
.				{
				  printf("error at line %d: bad character \"%s\"\n", linenum, yytext );
				  return;
				}

%%
void setPseudoComment( const char *text )
{
	/* format : //&[A-Z][+-] */
	switch( text[3] ) {
	 case 'S':
		if( text[4] == '+' )
			Opt_S = 1;
		else if( text[4] == '-' )
			Opt_S = 0;
		break;
	 case 'T':
		if( text[4] == '+' )
			Opt_T = 1;
		else if( text[4] == '-' )
			Opt_T = 0;
	 	break;
	 default:
	 	break;
	}

}