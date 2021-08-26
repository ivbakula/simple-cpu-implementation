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

struct frag fragS[256];
int text[256];

struct hash_table *symbols;

void generate_btype_alu(int opcode, bool do_reloc, uint8_t relax_type);
void generate_atype_alu(int opcode, bool do_reloc, uint8_t relax_type);
void generate_data(int opcode, bool do_reloc, uint8_t relax_type);
void generate_branch_cnd(int opcode, bool do_reloc, uint8_t relax_type);
void generate_branch_ucd(int opcode, bool do_reloc, uint8_t relax_type);
void generate_frag(union instr, uint8_t instr_type, bool do_reloc, uint8_t relax_type);
void clear_instr();
void insert_new_label();
void relax();
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
       program alu { clear_instr(); }
       | program data { clear_instr(); } 
       | program branch { clear_instr(); }
       | program special { clear_instr(); }
       | program pseudo { clear_instr(); }
       | program label { clear_instr(); }
       |
       ;

alu: OPCODE_ALU_BTYPE '%'reg1  ',' '%'reg2  ',' '%'regd 
	{ generate_btype_alu($1, false, RELAX_NONE); }

   | OPCODE_ALU_BTYPE '%'reg1  ',' '$'imm   ',' '%'regd 
	{ generate_btype_alu($1, false, RELAX_NONE); }

   | OPCODE_ALU_BTYPE '$'imm   ',' '%'reg2  ',' '%'regd 
	{ instr.B.hi = 1; generate_btype_alu($1, false, RELAX_NONE); }

   | OPCODE_ALU_BTYPE '$'LABEL ',' '%'reg2  ',' '%'regd 
	{ generate_btype_alu($1, true, RELAX_ABS); }

   | OPCODE_ALU_BTYPE '%'reg1  ',' '$'LABEL ',' '%'regd 
	{ generate_btype_alu($1, true, RELAX_ABS); }

   | OPCODE_ALU_ATYPE '%'reg1  ',' '%'regd 
	{ generate_atype_alu($1, false, RELAX_NONE); }

   | OPCODE_ALU_ATYPE '$'imm   ',' '%'regd 
	{ instr.A.hi = 1; generate_atype_alu($1, false, RELAX_NONE); }

   | OPCODE_ALU_ATYPE '$'LABEL ',' '%'regd 
	{ generate_atype_alu($1, true, RELAX_ABS); }
   ;

data: OPCODE_DATA_LOAD imm'(' '%'reg1')' ',' '%'regd 
	{ instr.A.hi = 1; generate_data($1, false, RELAX_NONE); }

    | OPCODE_DATA_LOAD '(' '%'reg1')'    ',' '%'regd 
	{ generate_data($1, false, RELAX_NONE); }

    | OPCODE_DATA_LOAD '('LABEL')' ',' '%'regd 
	{ generate_data($1, true, RELAX_PCREL); }

    | OPCODE_DATA_STORE '%'reg1 ',' '(' '%'regd')' 
	{ generate_data($1, false, RELAX_NONE); }

    | OPCODE_DATA_STORE '%'reg1 ',' imm'(' '%'regd')' 
	{ instr.A.hi = 1; generate_data($1, false, RELAX_NONE); }

    | OPCODE_DATA_STORE '%'reg1 ',' '('LABEL')' 
	{ generate_data($1, true, RELAX_PCREL); }
    ;

branch: OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' imm'(' '%'regd')' 
	{ generate_branch_cnd($1, false, RELAX_NONE); }

      | OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' imm 
	{ generate_branch_cnd($1, false, RELAX_NONE); }

      | OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' '(' '%'regd')' 
	{ generate_branch_cnd($1, false, RELAX_NONE); }

      | OPCODE_BRANCH_CND '%'reg1 ',' '%'reg2 ',' LABEL 
	{ generate_branch_cnd($1, true, RELAX_PCREL); }

      | OPCODE_BRANCH_UCD imm '(''%'regd')' 
	{ generate_branch_ucd($1, false, RELAX_NONE); }

      | OPCODE_BRANCH_UCD LABEL 
	{ generate_branch_ucd($1, true, RELAX_PCREL); }

      | OPCODE_BRANCH_UCD '(''%'regd')' 
	{ generate_branch_ucd($1, false, RELAX_NONE); }
      ;
pseudo:
      OPCODE_PSEUDO_INC '%'regd 
      { 
	instr_dt_fields.imm = 1; 
	instr.A.hi = 1; 
	generate_atype_alu(OPCODE_ADD, false, RELAX_NONE); 
      }	

      | OPCODE_PSEUDO_DEC '%'regd 
      { 
	instr.A.imm = 1; 
	instr.A.hi = 1; 
	generate_atype_alu(OPCODE_SUB, false, RELAX_NONE); 
      }

      | OPCODE_PSEUDO_MV '$'imm ',' '%'regd 
	{ instr.B.hi = 1; generate_btype_alu(OPCODE_ADDI, false, RELAX_NONE); }

      | OPCODE_PSEUDO_MV '%'reg1 ',' '%'regd 
	{ generate_btype_alu(OPCODE_ADDI, false, RELAX_NONE); }

      | OPCODE_PSEUDO_MV '$'LABEL ',' '%'regd
	{ generate_btype_alu(OPCODE_ADDI, true, RELAX_ABS); }

      | OPCODE_PSEUDO_NOP 
	{ generate_atype_alu(OPCODE_ADD, false, RELAX_NONE); } 
      ;


special: OPCODE_SPECIAL 
       { 
	instr.A.func = FUNC_BLOCK_SPECIAL; 
	instr.A.opcode= $1;
	generate_frag(instr, INSTR_TYPE_A, false, RELAX_NONE);
       } 
       ;

label: LABEL':' { insert_new_label(); }  
     ;

/*
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

void insert_new_label()
{
	int retval = ht_insert(symbols, yyname, pc);
	if (retval < 0) {
		char err[64];
		sprintf(err, "Error! Label \"%s\" already defined in section .text: %d\n",
				yyname, ht_get(symbols, yyname));
		yyerror(err);
		exit(-1);
	}

	memset(yyname, '\0', 64);
}

void generate_btype_alu(int opcode, bool reloc, uint8_t relax_type)
{
	instr.B.func = FUNC_BLOCK_ALU;
	instr.B.type = INSTR_TYPE_B;
	instr.B.opcode = opcode;	
	instr.B.rd = instr_dt_fields.regfile.regs.rd;
	instr.B.r1 = instr_dt_fields.regfile.regs.r1;
	instr.B.r2 = instr_dt_fields.regfile.regs.r2;
	instr.B.imm = instr_dt_fields.imm;

	generate_frag(instr, INSTR_TYPE_B, reloc, relax_type);
}

void generate_atype_alu(int opcode, bool reloc, uint8_t relax_type)
{
	instr.A.func = FUNC_BLOCK_ALU;
	instr.A.type = INSTR_TYPE_A;
	instr.A.opcode = opcode;
	instr.A.rd = instr_dt_fields.regfile.regs.rd;
	instr.A.r1 = instr_dt_fields.regfile.regs.r1;
	instr.A.imm = instr_dt_fields.imm;

	generate_frag(instr, INSTR_TYPE_A, reloc, relax_type);
}

void generate_data(int opcode, bool reloc, uint8_t relax_type)
{
	instr.A.func = FUNC_BLOCK_DATA;
	instr.A.type = INSTR_TYPE_A;
	instr.A.opcode = opcode;
	instr.A.rd = instr_dt_fields.regfile.regs.rd;
	instr.A.r1 = instr_dt_fields.regfile.regs.r1;
	instr.A.imm = instr_dt_fields.imm;

	generate_frag(instr, INSTR_TYPE_A, reloc, relax_type);
}

void generate_branch_cnd(int opcode, bool reloc, uint8_t relax_type) 
{ 
	instr.B.func = FUNC_BLOCK_BRANCH;
	instr.B.type = INSTR_TYPE_B;
	instr.B.opcode = opcode;
	instr.B.r1 = instr_dt_fields.regfile.regs.r1;
	instr.B.r2 = instr_dt_fields.regfile.regs.r2;
	instr.B.imm = instr_dt_fields.imm;

	if (!reloc) {
		if (!instr_dt_fields.regfile.regs.rd) instr.B.rd = 1;
		else instr.B.rd = instr_dt_fields.regfile.regs.rd;
	} 
	generate_frag(instr, INSTR_TYPE_B, reloc, relax_type);
}

void generate_branch_ucd(int opcode, bool reloc, uint8_t relax_type) 
{ 
	instr.C.func = FUNC_BLOCK_BRANCH;
	instr.C.type = INSTR_TYPE_C;
	instr.C.opcode = opcode;
	instr.C.rd = instr_dt_fields.regfile.regs.rd;
	instr.C.imm = instr_dt_fields.imm;

	generate_frag(instr, INSTR_TYPE_C, reloc, relax_type);
}

void debug_instr(struct frag *f)
{
	printf("func:   %x\n", f->instr.A.func);
	printf("type:   %x\n", f->instr.A.type);
	printf("opcode: %x\n", f->instr.A.opcode);
	printf("rd:     %x\n", f->instr.A.rd);

	switch (f->instr_type) {
		case INSTR_TYPE_A: 
			printf("r1:  %x\n", f->instr.A.r1); 
			printf("hi:  %x\n", f->instr.A.hi);
			printf("imm: %x\n", f->instr.A.imm);
			break;
                case INSTR_TYPE_B:
			printf("r1:  %x\n", f->instr.B.r1);
			printf("hi:  %x\n", f->instr.B.hi);
			printf("r2:  %x\n", f->instr.B.r2);
			printf("imm: %x\n", f->instr.B.imm);
			break;
		case INSTR_TYPE_C:
			printf("imm: %x\n", f->instr.C.imm);
			break;
	}

	printf("instr: %x\n", f->instr.data);
	puts("");
}

void debug_frag()
{
	struct frag *frag;
	for(frag = fragS; frag->label; frag++) {
//		debug_instr(frag->instr);
		printf("instr_type: %d\n", frag->instr_type);
		printf("relax_type: %d\n", frag->relax_type);
		printf("reloc:      %d\n", frag->reloc);
		printf("label:      %s\n", frag->label);
		printf("label_addr: %d\n", frag->label_addr);
		putchar('\n');
	}
}

void generate_frag(union instr instr, uint8_t instr_type, bool do_reloc, uint8_t relax_type)
{
	struct frag f = { .instr=instr, 
			.instr_type = instr_type,
			.relax_type = relax_type,
			.reloc = do_reloc,
			.label = strndup(yyname, 64),
			.label_addr = 0,
	};
	fragS[pc++] = f;
}

void clear_instr()
{
	instr.data = 0;
	instr_dt_fields.regfile.data = 0;
	instr_dt_fields.imm = 0;
}

void reloc()
{
	struct frag *f;
	for(f = fragS; f->label; f++) {
		if (!f->reloc) continue;

		// else
		f->label_addr = ht_get(symbols, f->label);
		if (f->label_addr < 0) {
			fprintf(stderr, "Linker error! " 
				"Undefined reference to %s " , f->label);
			exit(-1);
		}
	}
}

void relax_pcrel(struct frag *f, int pc_curr)
{
	int pcrel = 4 * (f->label_addr - pc_curr);
	printf("pcrel: %d\n", pcrel);
	switch(f->instr_type) {
		case INSTR_TYPE_A: f->instr.A.hi = 1;
				   f->instr.A.imm = pcrel;
				   f->instr.A.rd = 1;	// rd-pc
				   break;

		case INSTR_TYPE_B: f->instr.B.hi = 1;
				   f->instr.B.imm = pcrel;
				   f->instr.B.rd = 1;
				   break;
		case INSTR_TYPE_C: f->instr.C.imm = pcrel;
				   f->instr.C.rd = 1;
				   break;
	}
}

void relax_abs(struct frag *f)
{
	int offset = 4 * f->label_addr;
	printf("offset: %d\n", offset);
	switch(f->instr_type) {
		case INSTR_TYPE_A: f->instr.A.hi = 1; f->instr.A.imm = offset; break;
		case INSTR_TYPE_B: f->instr.B.hi = 1; f->instr.B.imm = offset; break;
		case INSTR_TYPE_C: f->instr.C.imm = offset; break;
	}
}

void relax()
{
	for(int i = 0; i <= pc; i++) {
		if (!fragS[i].relax_type) continue;

		// else
		if (fragS[i].relax_type == RELAX_PCREL)
			relax_pcrel(&fragS[i], i);

		else if (fragS[i].relax_type == RELAX_ABS)
			relax_abs(&fragS[i]);
	}
}

void print()
{
	for(int i = 0; i <= pc; i++) {
		text[i] = fragS[i].instr.data;
	}
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

	symbols = ht_create(999);
	yyparse();

	reloc();
	relax();

/*
	for (struct frag *f = fragS; f->label; f++) {
		debug_instr(f);
	}
	*/
//	debug_frag();

	print();
	if (!f_out)
		f_out = fopen("raw.out", "wb");
	fwrite(text, pc, sizeof(unsigned int), f_out);
	fclose(yyin);
	fclose(f_out);

	return 0;
}
