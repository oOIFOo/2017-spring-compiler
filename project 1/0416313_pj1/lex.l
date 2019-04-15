%{
	#include<stdio.h>
	#include<string.h>

	char tmp[100];
	char string_buf[100];
	int i = 0;
	int flag = 0;
%}

digit  	[0-9]
letter 	[A-Za-z]
oper	[+\-\*\/\:=\<\<=\<>\>=\>\=]

%%
and  {printf("and\n");}
or   {printf("or\n");}
not  {printf("not\n");}
mod  {printf("mod\n");}

array		{strcat(tmp,yytext);return 1;}
begin		{strcat(tmp,yytext);return 1;}
boolean		{strcat(tmp,yytext);return 1;}
def		{strcat(tmp,yytext);return 1;}
do		{strcat(tmp,yytext);return 1;}
else		{strcat(tmp,yytext);return 1;}
end		{strcat(tmp,yytext);return 1;}
false		{strcat(tmp,yytext);return 1;}
for		{strcat(tmp,yytext);return 1;}
integer		{strcat(tmp,yytext);return 1;}
if		{strcat(tmp,yytext);return 1;}
of		{strcat(tmp,yytext);return 1;}
print		{strcat(tmp,yytext);return 1;}
read		{strcat(tmp,yytext);return 1;}
real		{strcat(tmp,yytext);return 1;}
return  	{strcat(tmp,yytext);return 1;}
string  	{strcat(tmp,yytext);return 1;}
then		{strcat(tmp,yytext);return 1;}
to  		{strcat(tmp,yytext);return 1;}
true  		{strcat(tmp,yytext);return 1;}
var  		{strcat(tmp,yytext);return 1;}
while  		{strcat(tmp,yytext);return 1;}

"\n"	{return 69;}	

"//"  	{strcat(tmp,yytext);flag = 1; return 7;}	
		

{letter}+({letter}|{digit})* 	{strcat(tmp,yytext);return 3;}
{digit}+[.]{digit}+		{strcat(tmp,yytext);return 4;}
{digit}+			{strcat(tmp,yytext);return 5;}
[+-]*{digit}+[.]{digit}+[e]	{strcat(tmp,yytext);return 6;}

";"         	{strcat(tmp,yytext);return 2;}
"<="		{strcat(tmp,yytext);return 2;}
\+		{strcat(tmp,yytext);return 2;}
\-		{strcat(tmp,yytext);return 2;}
\*		{strcat(tmp,yytext);return 2;}
\/		{strcat(tmp,yytext);return 2;}
:=		{strcat(tmp,yytext);return 2;}
\<		{strcat(tmp,yytext);return 2;}
\>		{strcat(tmp,yytext);return 2;}
>=		{strcat(tmp,yytext);return 2;}
"<>"		{strcat(tmp,yytext);return 2;}
\:		{strcat(tmp,yytext);return 2;}
\,		{strcat(tmp,yytext);return 2;}
\(		{strcat(tmp,yytext);return 2;}
\)		{strcat(tmp,yytext);return 2;}
\[		{strcat(tmp,yytext);return 2;}
\]		{strcat(tmp,yytext);return 2;}

"/*"		{strcat(tmp,yytext);flag = 4;return 7;}
"*/"		{strcat(tmp,yytext);flag = 1;return 10;}


\"		{
			strcat(tmp,yytext);
			if(flag == 0) {flag = 2;return 7;}
			if(flag == 2) {flag = 1;return 10;}
			return 70;
		}


.		{
			strcat(tmp,yytext);
			return 99;
		}

%%
int main(int argc, char** argv) {
  int buf = 0;
  yyin = fopen(argv[1],"r");
  while(1){
	buf = yylex();

	if(buf != 10 && flag != 0){strcat(string_buf,yytext);strcat(string_buf," ");}	
	if(buf == 1 && flag == 0){printf("<KW: %s>\n", yytext);}
	if(buf == 2 && flag == 0){printf("<%s>\n", yytext);}
	if(buf == 3 && flag == 0){printf("<id: %s>\n", yytext);}
	if(buf == 4 && flag == 0){printf("<float: %s>\n", yytext);}
	if(buf == 5 && flag == 0){printf("<integer: %s>\n", yytext);}
	if(buf == 6 && flag == 0){printf("<scientific: %s>\n", yytext);}
	if(buf == 69 && flag != 4){
				printf("%d: ", i);
				printf("%s\n", tmp);
				i++;
				strcpy(tmp,"");
				strcpy(string_buf,"");
				flag = 0;
			}
	if(flag == 1 && buf == 10){printf("<string: %s>\n", string_buf);flag = 0;}
  }
  return 0;
}

yywrap() { fclose(yyin); exit(1);}