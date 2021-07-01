%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "hashtable.h"

int yylex(void);
void yyerror(char *);

extern int yyline; 
extern FILE *yyin;
extern char yyname[256];

struct instruction_fields {
	unsigned int imm : 16;
	unsigned int rd : 4;
	unsigned int rs : 4;
	unsigned int opcode : 6;
	unsigned int prefix : 2;
};

union encode_instruction {
	unsigned int data;
	struct instruction_fields f;
};

struct label_fields {
	unsigned int prefix : 8;
	unsigned int value : 16;
	unsigned int suffix : 8;
};

struct prefix {
	unsigned char dst;
	unsigned char src;
};

union encode_prefix {
	unsigned char data;
	struct prefix p;
};

void debug_instruction();
void insert_new_label();
void derefer_label(unsigned short *);

struct hash_table *names;

unsigned int text[256] = {0};
int current = 0;
union encode_instruction instr;
union encode_prefix pfix;


%}

%token CONST
%token LABEL

%token REGISTER

%token OPCODE_BINARY
%token OPCODE_UNARY		 
%token OPCODE_SINGLE		/* halt, nop */
%token HALT
%token NOP
%token OUTW

%%
program: 
       program binary { 
			instr.f.prefix = pfix.data;
			text[current++] = instr.data;
			pfix.data = 0; instr.data = 0;
		    }
       | program unary {
			 instr.f.prefix = pfix.data;
			 text[current++] = instr.data;
			 debug_instruction();
			 pfix.data = 0; instr.data = 0;
		       }
       | program single { 
				instr.f.prefix = 0;  
				text[current++] = instr.data; 
				pfix.data = 0; instr.data = 0; 
			}
       | program LABEL ':'  { insert_new_label(); pfix.data = 0; }
       |
       ;


binary:
    OPCODE_BINARY src ',' dst { instr.f.opcode = $1; }
    ;

unary:
     OPCODE_UNARY src { instr.f.opcode = $1; }
     | OPCODE_UNARY LABEL {
				instr.f.opcode = $1; 
				pfix.data = 3;
				unsigned short val = 0;
				derefer_label(&val); 
				instr.f.imm = val;
			   }
     ;
	
single:
      OPCODE_SINGLE { instr.f.opcode = $1; }
      ;

src:
   REGISTER     { pfix.p.src  = 0; instr.f.rs  = $1; }
   | '$' CONST	{ pfix.data = 3; instr.f.imm = $2; }   /* constant integer */
   | '&' CONST  { pfix.p.src  = 1; instr.f.imm = $2; } /* memory address */
   ;

dst:
   REGISTER     { 
			instr.f.rd = $1;
			if (pfix.data != 3)
				pfix.p.dst = 0;
		}

   | '&' CONST  { 
			if (pfix.data == 3) {
				char err[256] = "\0"; 
				sprintf(err, 
					"Syntax error! Illegal combination of "
					"source and destination "
					"on the line: %d\n", yyline);
				yyerror(err);
				return -1;
			} else {
				pfix.p.dst = 1;
				instr.f.imm = $2;
			}
		}
   ;

%%

void debug_instruction()
{
	printf("prefix: %d\n", pfix.data); 
	printf("opcode: %d\n", instr.f.opcode);
	printf("rs: %d\n", instr.f.rs);
	printf("rd: %d\n", instr.f.rd);
	printf("imm: %d\n", instr.f.imm);
	printf("%x\n", instr.data);
}

void derefer_label(unsigned short *dst)
{
	unsigned long label = ht_get(names, yyname);
	if (label < 0) {
		char err[256];
		sprintf(err, "Error! Label %s not defined.", yyname);
		yyerror(err);
		exit(-1);
	}
	
	if (label < USHRT_MAX) {
		printf("%d\n", label);
		*dst = (unsigned short) label;
	}
}

void insert_new_label()
{
	int retval = ht_insert(names, yyname, current);
	if (retval < 0) {
		char err[256];
		sprintf(err, "Error! Label %s already defined on the line: %d\n",
				names, ht_get(names, yyname));
		yyerror(err);
		exit(-1);
	}
	memset(yyname, '\0', 256);
}

int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");
	names = ht_create(999);
	yyparse();
	
	FILE *out = fopen("raw.out", "wb");
	fwrite(text, current , sizeof(unsigned int), out);
	fclose(yyin);
	fclose(out);
	return 0;
}
