%{

#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

void yyerror(char *);
void invalid_token(char );
void comment();
int genreg(char );
int bin2int(char*, int *);
int yyline = 1;

char yyname[256];

%}

NEG -
DEC [0-9]+[0-9]*
HEX 0x[0-9A-Fa-f]+
BIN 0b[0-1]+
NAME [._a-zA-Z]+
%%
[\t ] ;
\n { yyline++; }
"/*" { comment(); }

[&$,:()%] return *yytext;

"rzero"|"RZERO" { yylval = 0; return REGISTER; }
"pc"|"PC" { yylval = 1; return REGISTER; }
"ra"|"RA" { yylval = 2; return REGISTER; }
"rsp"|"RSP" { yylval = 3; return REGISTER; }
"rbp"|"RBP" { yylval = 4; return REGISTER; }

("gpr"|"GPR")[0-9] { yylval = genreg(yytext[3]); return REGISTER; }

"add"|"ADD" { yylval = 0; return OPCODE_ALU_ATYPE; }
"addi"|"ADDI" { yylval = 1; return OPCODE_ALU_BTYPE; }
"sub"|"SUB" { yylval = 2; return OPCODE_ALU_ATYPE; }
"shr"|"SHR" { yylval = 3; return OPCODE_ALU_ATYPE; }
"shl"|"SHL" { yylval = 4; return OPCODE_ALU_ATYPE; }
"and"|"AND" { yylval = 5; return OPCODE_ALU_ATYPE; }
"or"|"OR" { yylval = 6; return OPCODE_ALU_ATYPE; }
"xor"|"XOR" { yylval = 7; return OPCODE_ALU_ATYPE; }

"sdw"|"SDW" { yylval = 0; return OPCODE_DATA_STORE; }
"sw"|"SW" { yylval = 1; return OPCODE_DATA_STORE; }
"sb"|"SB" { yylval = 2; return OPCODE_DATA_STORE; }
"ldw"|"LDW" { yylval = 3; return OPCODE_DATA_LOAD; }
"lw"|"LW" { yylval = 4; return OPCODE_DATA_LOAD; }
"lb"|"LB" { yylval = 5; return OPCODE_DATA_LOAD; }
"out"|"out" { yylval = 6; return OPCODE_DATA_LOAD; }
"in"|"IN" { yylval = 7; return OPCODE_DATA_STORE; }

"beq"|"BEQ" { yylval = 0; return OPCODE_BRANCH_CND; }
"bne"|"BNE" { yylval = 1; return OPCODE_BRANCH_CND; }
"bgt"|"BGT" { yylval = 2; return OPCODE_BRANCH_CND; }
"blt"|"BLT" { yylval = 3; return OPCODE_BRANCH_CND; }
"bge"|"BGE" { yylval = 4; return OPCODE_BRANCH_CND; }
"ble"|"BLE" { yylval = 5; return OPCODE_BRANCH_CND; }
"brn"|"BRN" { yylval = 6; return OPCODE_BRANCH_UCD; }

"inc"|"INC" { yylval = 0; return OPCODE_PSEUDO_INC; }
"dec"|"DEC" { yylval = 1; return OPCODE_PSEUDO_DEC; }
"mv"|"MV" { yylval = 2; return OPCODE_PSEUDO_MV; }
"call"|"CALL" { yylval = 3; return OPCODE_PSEUDO_CALL; }
"ret"|"RET" { yylval = 4; return OPCODE_PSEUDO_RET; }
"nop"|"NOP" { yylval = 5; return OPCODE_PSEUDO_NOP; }

"hlt"|"HLT" { yylval = 7; return OPCODE_SPECIAL; }

{NEG}?{HEX} { yylval = (int)strtol(yytext, NULL, 0); printf("yylval = %d\n", yylval); return CONST; }
{NEG}?{BIN} { bin2int(yytext, &yylval); return CONST; }
{NEG}?{DEC} { yylval = atoi(yytext); return CONST; }
".text" { return TEXT; }
".data" { return DATA; }
{NAME} { strncpy(yyname, yytext, 256); return LABEL; }

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

int genreg(char c)
{
	return ((c - 48) + 5);
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
