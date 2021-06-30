%{
#include <stdio.h>
int yylex(void);
extern int yyline; 
extern FILE *yyin;

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

struct prefix {
	unsigned char dst;
	unsigned char src;
};

union encode_prefix {
	unsigned char data;
	struct prefix p;
};

unsigned int text[256] = {0};
int current = 0;
union encode_instruction instr;
union encode_prefix pfix;

void debug_instruction();

%}

%token CONST
%token REGISTER
%token OPCODE
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
       | program single { 
				instr.f.prefix = 0;  
				text[current++] = instr.data; 
				pfix.data = 0; 
				instr.data = 0; 
			}
       |
       ;

single:
    HALT { instr.f.opcode = $1; }
    | OUTW { instr.f.opcode = $1; }
    | NOP { instr.f.opcode = $1; }
    ;

binary:
    OPCODE src ',' dst { instr.f.opcode = $1; }
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

int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");
	yyparse();

	for (int i = 0; i < current; i++) 
		printf("%x\n", text[i]);

	FILE *out = fopen("raw.out", "wb");
	fwrite(text, current , sizeof(unsigned int), out);
	fclose(yyin);
	fclose(out);
	return 0;
}
