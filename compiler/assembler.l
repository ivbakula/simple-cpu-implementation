%{

#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

void yyerror(char *);
void invalid_token(char );
void comment();
int bin2int(char*, int *);
int yyline = 1;

char yyname[256];

%}

DEC [0-9]+[0-9]*
HEX 0x[0-9A-Fa-f]+
BIN 0b[0-1]+
NAME \.[0-9A-Za-z]+
%%
[\t ] ;
\n { yyline++; }
"/*" { comment(); }

[&$,:()] return *yytext;

{HEX} { yylval = (int)strtol(yytext, NULL, 0); return CONST; }
{BIN} { bin2int(yytext, &yylval); return CONST; }
{DEC} { yylval = atoi(yytext); return CONST; }
{NAME} { strncpy(yyname, yytext, 256); return LABEL; }

"r0"|"R0"   { yylval = 0x0; return REGISTER; }
"r1"|"R1"   { yylval = 0x1; return REGISTER; }
"r2"|"R2"   { yylval = 0x2; return REGISTER; }
"r3"|"R3"   { yylval = 0x3; return REGISTER; }
"r4"|"R4"   { yylval = 0x4; return REGISTER; }
"r5"|"R5"   { yylval = 0x5; return REGISTER; }
"r6"|"R6"   { yylval = 0x6; return REGISTER; }
"r7"|"R7"   { yylval = 0x7; return REGISTER; }
"r8"|"R8"   { yylval = 0x8; return REGISTER; }
"r9"|"R9"   { yylval = 0x9; return REGISTER; }
[rR][aA]    { yylval = 0xa; return REGISTER; }
[rR][bB]    { yylval = 0xb; return REGISTER; }
[rR][cC]    { yylval = 0xc; return REGISTER; }
[rR][dD]    { yylval = 0xd; return REGISTER; }
"rsp"|"RSP" { yylval = 0xe; return REGISTER; }
"rbp"|"RBP" { yylval = 0xf; return REGISTER; }

"nop"|"NOP" { yylval = 0x0; return OPCODE_SINGLE; }
"and"|"AND" { yylval = 0x1; return OPCODE_BINARY; }
"or"|"OR"   { yylval = 0x2; return OPCODE_BINARY; }
"xor"|"XOR" { yylval = 0x3; return OPCODE_BINARY; }

"mov"|"MOV" { yylval = 0x4; return OPCODE_BINARY; }
"add"|"ADD" { yylval = 0x5; return OPCODE_BINARY; }
"sub"|"SUB" { yylval = 0x6; return OPCODE_BINARY; }

"outb"|"OUTB" { yylval = 0x7; return OPCODE_UNARY; }
"outl"|"OUTL" { yylval = 0x8; return OPCODE_UNARY; }

"inb" | "INB" { yylval = 0x9; return OPCODE_UNARY; }
"inl"|"INL" { yylval = 0xa; return OPCODE_UNARY; }

"jlt"|"JLT" { yylval = 0xb; return OPCODE_UNARY; }
"jgt"|"JGT" { yylval = 0xc; return OPCODE_UNARY; }
"jle"|"JLE" { yylval = 0xd; return OPCODE_UNARY; }
"jge"|"JGE" { yylval = 0xe; return OPCODE_UNARY; }

"je"|"JE" { yylval = 0xf; return OPCODE_UNARY; }
"jmp"|"JMP" { yylval = 0x10; return OPCODE_UNARY; }

"hlt"|"HLT"  { yylval = 0x11; return OPCODE_SINGLE; }
"cmp"|"CMP"  { yylval = 0x12; return OPCODE_BINARY; }

. { invalid_token(yytext[0]); }

%%

int yywrap(void)
{
	return 1;
}

void yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
}

void comment()
{
	char c, c1;
loop:
	while((c = input()) != '*' && c != 0)
		; 

	if((c1 = input()) != '/' && c != 0) {
		unput(c1);
		goto loop;
	}
}

void invalid_token(char c0)
{
	char err[256];
	char c;
	int i = 1;
	err[0] = c0 ;
	while((c = input()) != ' ' && c != '\t' && c != '\n' && c != 0 && i < 255)
		err[i++] = c;

	fprintf(stderr, "Error on the line %d! Invalid token %s", yyline, err);
}

int bin2int(char *bin, int *num)
{
	int len = strlen(bin);
	unsigned int conv = 0;
	unsigned int curr = 0;
	if (len < 3) {
		return -1;			/* too short */
	}

	if (bin[0] != '0' && bin[1] != 'b') {
		return -2;			/* invalid format */
	}

	for (int i = 2; i < len; i++) {
		if (bin[i] != '0' && bin[i] != '1')
		    return -3;			/* unexpected character */

		curr = (bin[i] - 48) << (len - i - 1);
		conv |= curr;
	}

	*num = conv;
	return 0;
}
