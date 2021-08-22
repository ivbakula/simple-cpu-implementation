%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdbool.h>

#include "hashtable.h"
#include "types.h"

#define DEBUG_INSTR
int yylex(void);
void yyerror(char *);

extern int yyline; 
extern FILE *yyin;
extern char yyname[64];

union instr instr;
struct instr_dt_fields instr_dt_fields;		// instrution data fields
int instr_type;
int pc;
int text[256];

/*
int section;
struct text *text_section;
struct data *data_section;
*/

void generate_btype_alu(int );
void generate_atype_alu(int );
void generate_data(int );
void generate_branch_cnd(int, bool );
void generate_branch_ucd(int, bool );
void generate_instr();
%}

%token CONST
%token LABEL

%token REGISTER
%token OPCODE_ALU_BTYPE
%token OPCODE_ALU_ATYPE
%token OPCODE_DATA_LOAD
%token OPCODE_DATA_STORE
%token OPCODE_BRANCH_CND	/* conditional branch */
%token OPCODE_BRANCH_UCD	/* unconditional branch */
%token OPCODE_PSEUDO_INC
%token OPCODE_PSEUDO_DEC
%token OPCODE_PSEUDO_MV
%token OPCODE_PSEUDO_CALL
%token OPCODE_PSEUDO_RET
%token OPCODE_PSEUDO_NOP
%token OPCODE_SPECIAL

%token TEXT
%token DATA

%%
program: 
       program alu { generate_instr(); }
       | program data { generate_instr(); } 
       | program branch { generate_instr(); }
       | program special { generate_instr(); }
       | program pseudo { generate_instr(); }
       |
       ;

alu: OPCODE_ALU_BTYPE '%'reg1  ',' '%'reg2  ',' '%'regd { generate_btype_alu($1); }
   | OPCODE_ALU_BTYPE '%'reg1  ',' '$'imm   ',' '%'regd { generate_btype_alu($1); }
   | OPCODE_ALU_BTYPE '$'imm   ',' '%'reg2  ',' '%'regd { generate_btype_alu($1); }
   | OPCODE_ALU_BTYPE '$'LABEL ',' '%'reg2  ',' '%'regd { generate_btype_alu($1); }
   | OPCODE_ALU_BTYPE '%'reg1  ',' '$'LABEL ',' '%'regd { generate_btype_alu($1); }
   | OPCODE_ALU_ATYPE '%'reg1  ',' '%'regd { generate_atype_alu($1); }
   | OPCODE_ALU_ATYPE '$'imm   ',' '%'regd { instr.A.hi = 1; generate_atype_alu($1); }
   | OPCODE_ALU_ATYPE '$'LABEL ',' '%'regd { generate_atype_alu($1); }
   ;

data: OPCODE_DATA_LOAD imm'(' '%'reg1')' ',' '%'regd { generate_data($1); }
    | OPCODE_DATA_LOAD '(' '%'reg1')'    ',' '%'regd { generate_data($1); }
    | OPCODE_DATA_STORE '%'reg1 ',' '(' '%'regd')' { generate_data($1); }
    | OPCODE_DATA_STORE '%'reg1 ',' imm'(' '%'regd')' { generate_data($1); }
    ;

branch: OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' imm'(' '%'regd')' { generate_branch_cnd($1, false); }
      | OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' imm { generate_branch_cnd($1, true); }
      | OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' '(' '%'regd')' { generate_branch_cnd($1, false); }
      | OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' LABEL { generate_branch_cnd($1, true); }
      | OPCODE_BRANCH_UCD imm '%''('regd')' { generate_branch_ucd($1, false); }
      | OPCODE_BRANCH_UCD LABEL { generate_branch_ucd($1, true); }
      ;
pseudo:
      OPCODE_PSEUDO_INC '%'regd 
      { instr_dt_fields.imm = 1; instr.A.hi = 1; generate_atype_alu(OPCODE_ADD); }
      | OPCODE_PSEUDO_DEC '%'regd { instr.A.imm = 1; instr.A.hi = 1; generate_atype_alu(OPCODE_SUB); }
      | OPCODE_PSEUDO_MV '$'imm ',' '%'regd { generate_btype_alu(OPCODE_ADDI); }
      | OPCODE_PSEUDO_MV '%'reg1 ',' '%'regd { generate_btype_alu(OPCODE_ADDI); }
      | OPCODE_PSEUDO_NOP { generate_atype_alu(OPCODE_ADD); } 
      ;


special: OPCODE_SPECIAL { instr.A.opcode = $1; } 
       ;

/*
label: LABEL':' { insert_new_label(); }  
     ;

section: TEXT { section = SECTION_TEXT; index = 0; }
       | DATA { section = SECTION_DATA; index = 0; }
       ;
*/
regd: REGISTER { instr_dt_fields.regfile.regs.rd = $1; }
    ;
reg1: REGISTER { instr_dt_fields.regfile.regs.r1 = $1; } 
    ;
reg2: REGISTER { instr_dt_fields.regfile.regs.r2 = $1; } 
    ;
imm: CONST { instr_dt_fields.imm = $1; }
%%

void generate_btype_alu(int opcode)
{
	instr.B.func = FUNC_BLOCK_ALU;
	instr.B.type = INSTR_TYPE_B;
	instr.B.opcode = opcode;	
	instr.B.rd = instr_dt_fields.regfile.regs.rd;
	instr.B.r1 = instr_dt_fields.regfile.regs.r1;
	instr.B.r2 = instr_dt_fields.regfile.regs.r2;
	instr.B.imm = instr_dt_fields.imm;
}

void generate_atype_alu(int opcode)
{
	instr.A.func = FUNC_BLOCK_ALU;
	instr.A.type = INSTR_TYPE_A;
	instr.A.opcode = opcode;
	instr.A.rd = instr_dt_fields.regfile.regs.rd;
	instr.A.r1 = instr_dt_fields.regfile.regs.r1;
	instr.A.imm = instr_dt_fields.imm;
}

void generate_data(int opcode)
{
	instr.A.func = FUNC_BLOCK_DATA;
	instr.A.type = INSTR_TYPE_A;
	instr.A.opcode = opcode;
	instr.A.rd = instr_dt_fields.regfile.regs.rd;
	instr.A.r1 = instr_dt_fields.regfile.regs.r1;
	instr.A.imm = instr_dt_fields.imm;
}

void generate_branch_cnd(int opcode, bool regd_pc) 
{ 
	instr.B.func = FUNC_BLOCK_BRANCH;
	instr.B.type = INSTR_TYPE_B;
	instr.B.opcode = opcode;
	instr.B.r1 = instr_dt_fields.regfile.regs.r1;
	instr.B.r2 = instr_dt_fields.regfile.regs.r2;
	instr.B.imm = instr_dt_fields.imm;
	if (regd_pc) instr.B.rd = 1;
	else instr.B.rd = instr_dt_fields.regfile.regs.rd;
}

void generate_branch_ucd(int opcode, bool regd_pc) { }

void debug_instr()
{
	printf("func:   %x\n", instr.A.func);
	printf("type:   %x\n", instr.A.type);
	printf("opcode: %x\n", instr.A.opcode);
	printf("rd:     %x\n", instr.A.rd);

	switch (instr.A.type) {
		case INSTR_TYPE_A: 
			printf("r1:  %x\n", instr.A.r1); 
			printf("hi:  %x\n", instr.A.hi);
			printf("imm: %x\n", instr.A.imm);
			break;
                case INSTR_TYPE_B:
			printf("r1:  %x\n", instr.B.r1);
			printf("hi:  %x\n", instr.B.hi);
			printf("r2:  %x\n", instr.B.r2);
			printf("imm: %x\n", instr.B.imm);
			break;
		case INSTR_TYPE_C:
			printf("imm: %x\n", instr.C.imm);
			break;
	}

	printf("instr: %x\n", instr.data);
	puts("");
}

void generate_instr()
{
#ifdef DEBUG_INSTR
	debug_instr();
#endif
	text[pc++] = instr.data;
	instr.data = 0;
	instr_dt_fields.regfile.data = 0;
	instr_dt_fields.imm = 0;
}

int main(int argc, char *argv[])
{
	FILE *f_out = NULL;
	pc = 0;
	instr.data = 0;
	instr_dt_fields.regfile.data = 0;
	instr_dt_fields.imm = 0;
	yyin = fopen(argv[1], "r");

	if (argc > 2) {
		if(!strcmp("-o", argv[2] ) && argc > 3)
			f_out = fopen(argv[3], "wb");
		else {
			fprintf(stderr, "Usage: as <input file> -o <output_file>");
			exit(-1);
		}
	}


	yyparse();
	if (!f_out)
		f_out = fopen("raw.out", "wb");
	fwrite(text, pc, sizeof(unsigned int), f_out);
	fclose(yyin);
	fclose(f_out);

	return 0;
}
