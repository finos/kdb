/** 
 * @file qoxygen.l
 *
 * Convert q/kdb+ code into a c like script that doxygen might understand.
 */



%option stack
%s def defbody fn args fnbody doc
%x end table string block coldata
%option noyywrap
%{
	#include <string.h>	
	#define MAXLENGTH 256
	//Allocated in main function and used on line 26
	char* func = NULL;
%}

%%
 /*****************************************
  * convert definitions to c style functions
  * and variables
  */
<INITIAL>^[ \t]*(".")?[[:alpha:]]([[:alnum:]]|"."|"_")*[ \t]*/: {
	strcpy(func,yytext);
	yy_push_state(def);
}

<INITIAL>^[ \t]*\\d[ \t]*([[:alnum:]]|"."|"_")*$ {
        //Change of context..
	printf("%s", yytext);
}

<INITIAL>^[ \t]*\\l[ \t]*([[:alnum:]]|"."|"_"|"\/")*$ {
        //Change of context..
        printf("%s", yytext);
}


<INITIAL>^[\t]*\/\/.*$ {
	// Double slash comment.
        printf("%s", yytext);
}

<INITIAL>^[\t]*\/[\t].*$ {
	// Single slash comment.
        printf("%s", yytext);
}


<def>:[ \t]* {
	yy_pop_state();
	yy_push_state(defbody);
}

<defbody>[\r\n]+ {
	printf(";\n");
	yy_pop_state();
}

<defbody>[ \t]+\/[^:] {
	printf("; ");
	yy_pop_state();
}

<defbody>[,;] {
	printf(" ");
}

<def>:[ \t]*\{[ \t]* {
	printf("function %s (",func);
	yy_pop_state();
	yy_push_state(fn);
	
}

<fn>\[ {
	yy_pop_state();
	yy_push_state(args);
}

<args>; {
	printf(",");
	yy_pop_state();
	yy_push_state(args);
}

<args>[[:alnum:]]* {
	printf("%s",yytext);
        yy_pop_state();
        yy_push_state(args);	
}

<fn>. |
<args>\] {
	printf(") {");
	yy_pop_state();
	yy_push_state(fnbody);
}


<fn,fnbody>\" {
	printf("%s", yytext);
	yy_push_state(string);
}

<string>(\\\"|\\\\) {
	printf("%s", yytext);
}
<string>\" {
	printf("%s", yytext);
	yy_pop_state();
}

<fn,fnbody>\} {
	printf("};");
	yy_pop_state();
}

<fnbody>\{ {
        yy_push_state(block);
}


<fnbody>(.|[\r\n]+) {
	//printf(".");
}


<block>\} {
	yy_pop_state();
}

<block>\{ {
	yy_push_state(block);
}
<block>. {
}


 /*****************************************
  * remove anything left over
  */ 


.

%%


int main(int argc, char **argv) {
	func = (char *) malloc(MAXLENGTH);
	yyin = (argc>1) ? fopen(argv[1], "r") : stdin;
	yylex();
	free(func);
	return 0;
}
