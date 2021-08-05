%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdbool.h>

#include "hashtable.h"
#define DEBUG_INSTRUCTION
int yylex(void);
void yyerror(char *);

extern int yyline; 
extern FILE *yyin;
extern char yyname[256];

struct instruction_fields {
	int imm : 16;
	unsigned int rd : 4;
	unsigned int rs : 4;
	unsigned int opcode : 5;
	unsigned int func: 2;
	unsigned int has_imm: 1;
};

union encode_instruction {
	unsigned int data;
	struct instruction_fields f;
};

struct code {
	bool has_reference;
	unsigned int index;
	unsigned int instruction;
	char symbol[256];
	struct code *next;
};

bool is_labeled = false;	/* instruction contains label? */
struct code *tail = NULL;	/* last generated entry */
struct code *gen_code = NULL;	/* code generated by assembler */

void debug_instruction();
void generate_instruction();
void insert_new_label();
void derefer_label();

struct hash_table *symbols;

unsigned int text[256] = {0};
int current = 0;
union encode_instruction instr;

#define INSTR_INC_RSP 0x840e0001
#define INSTR_DEC_RSP 0x850e0001
#define INSTR_PUSH_PC 0x33d00000
#define INSTR_POP_PC  0x340d0000
#define INSTR_BRN_PC  0x52d00000
#define INSTR_INC_PC  0x840d0001

%}

%token CONST
%token LABEL

%token REGISTER
%token OPCODE_NOP
%token OPCODE_RD
%token OPCODE_WR
%token OPCODE_ALU
%token OPCODE_HLT
%token OPCODE_IO
%token OPCODE_BRANCH_CD      // conditional branch
%token OPCODE_BRANCH_UCD     // unconditional branch

%token OPCODE_PUSH
%token OPCODE_POP

%token OPCODE_CALL
%token OPCODE_RET

%%
program: 
       program alu{ generate_instruction(); }
       | program mem_rd { generate_instruction(); }
       | program mem_wr { generate_instruction(); }
       | program brnch { generate_instruction(); }
       | program stack { generate_instruction(); } 
       | program subroutine { generate_instruction(); }
       | program io { generate_instruction(); }
       | program halt { generate_instruction(); }
       | program nop { generate_instruction(); }
       | program LABEL ':'  { insert_new_label(); }
       |
       ;


halt:
    OPCODE_HLT 
	{ 
		instr.f.opcode = $1; 
	}
	;
nop:
   OPCODE_NOP
	{
		instr.data = 0;
	}
	;
io:
  OPCODE_IO '%'src_reg
	{
	        instr.f.has_imm= 0;
		instr.f.func = 3;
		instr.f.opcode = $1;
	}
	;
alu:
   OPCODE_ALU '%'src_reg',' '%'dst_reg
	{ 
		instr.f.has_imm= 0;
		instr.f.func = 0;
		instr.f.opcode = $1; 
	}
   | OPCODE_ALU '$'imm ',' '%'dst_reg
	{
		instr.f.has_imm = 1;
		instr.f.func = 0;
		instr.f.opcode = $1;
	}
   | OPCODE_ALU '$'LABEL ',' '%'dst_reg
	{
	        instr.f.has_imm = 1;
		instr.f.func = 0;
		instr.f.opcode = $1;
		is_labeled = true;
	}
   ;

mem_rd:
      OPCODE_RD '('LABEL')'',' '%'dst_reg
	{
	        instr.f.has_imm = 1;
		instr.f.func = 1;
		instr.f.opcode = $1;
	}
      | OPCODE_RD '('imm')' ',' '%'dst_reg
	{
	        instr.f.has_imm = 1;
		instr.f.func = 1;
		instr.f.opcode = $1;
	}
      | OPCODE_RD '$'imm ',' '%'dst_reg
        {
		instr.f.has_imm = 1;
		instr.f.func = 1;
		instr.f.opcode = $1;
	}
      | OPCODE_RD '%'src_reg ',' '%'dst_reg
	{
		instr.f.has_imm = 0;
		instr.f.func = 1;
		instr.f.opcode = $1;
	}
      ;

mem_wr:
      OPCODE_WR '%'src_reg ',' '('LABEL')'
	{
		instr.f.has_imm = 1; 
		instr.f.func = 1;
		instr.f.opcode = $2;
		is_labeled = true;
	}
      | OPCODE_WR '%'src_reg',' '('imm')'
        {
		instr.f.has_imm = 1;
		instr.f.func = 1;
		instr.f.opcode = $1;
	}
      ;

stack:
     OPCODE_PUSH '%'src_reg
	{
		unsigned int tmp = instr.data;
		instr.data = INSTR_INC_RSP;
		generate_instruction();

		instr.data = tmp;
		instr.f.has_imm = 0;
		instr.f.func = 1;
		instr.f.opcode = $1;
	}
    | OPCODE_POP '%'dst_reg
	{
		instr.f.has_imm = 0;
		instr.f.func = 1;
		instr.f.opcode = $1;
		generate_instruction();

		instr.data = INSTR_DEC_RSP;
	}
    ;

brnch:
     OPCODE_BRANCH_CD '%'src_reg ',' '%'dst_reg ',' LABEL
	{
		instr.f.has_imm = 1;
		instr.f.func = 2;
		instr.f.opcode = $2;
		is_labeled = true;
	}
     | OPCODE_BRANCH_CD '%'src_reg ',' '%'dst_reg ',' imm
	{
		instr.f.has_imm = 1;
		instr.f.func = 2;
		instr.f.opcode = $1;
	}
     | OPCODE_BRANCH_UCD LABEL
	{
		instr.f.has_imm = 1;
		instr.f.func = 2;
		instr.f.opcode = $2;
		is_labeled = true;
	}
     | OPCODE_BRANCH_UCD imm
	{
		instr.f.has_imm = 1;
		instr.f.func = 2;
		instr.f.opcode = $1;
	}
     | OPCODE_BRANCH_UCD '%' src_reg
	{
		instr.f.has_imm = 0;
		instr.f.func = 2;
		instr.f.opcode = $1;
	}
     ;

imm:
   CONST {instr.f.imm = $1; }
   ;
   
src_reg:
       REGISTER { instr.f.rs = $1; }
       ;
dst_reg:
       REGISTER { instr.f.rd = $1; }
       ;
%%

void debug_instruction()
{
	printf("has_imm: %d\n", instr.f.has_imm); 
	printf("func: %d\n", instr.f.func);
	printf("opcode: %d\n", instr.f.opcode);
	printf("rs: %d\n", instr.f.rs);
	printf("rd: %d\n", instr.f.rd);
	printf("imm: %d\n", instr.f.imm);
	printf("%x\n", instr.data);
}

struct code *new_slot(bool has_reference, char *label)
{
	struct code *c = (struct code *) malloc(sizeof(*c));
	if (!c)
		return NULL;

	c->has_reference = has_reference;
	c->instruction = instr.data; 
	c->index = current;
	if (has_reference)
		strncpy(c->symbol, label, 256);

	current++;

	return c;
}

void generate_instruction()
{
#ifdef DEBUG_INSTRUCTION
	debug_instruction();
#endif
	if (tail == NULL) {
		gen_code = new_slot(is_labeled, yyname);
		tail = gen_code;
	} else {
		tail->next = new_slot(is_labeled, yyname);
		tail = tail->next;
	}

	if (is_labeled)
		memset(yyname, '\0', 256);

	is_labeled = false;
	instr.data = 0;
}

void insert_new_label()
{
	int retval = ht_insert(symbols, yyname, current);
	if (retval < 0) {
		char err[256];
		sprintf(err, "Error! Label \"%s\" already defined in section .text: %d\n",
				yyname, ht_get(symbols, yyname));
		yyerror(err);
		exit(-1);
	}
	memset(yyname, '\0', 256);
}

void link()
{
	struct code *head = gen_code;
	union encode_instruction ei; 
	int refval;			/* memory location of reference */
	if (!head)
		return;
	
	while(head) {
		ei.data = head->instruction;
		if (head->has_reference) {
			refval = ht_get(symbols, head->symbol);
			if (refval < 0) {
				fprintf(stderr, "Linker error! "
					"Undefined reference to %s in "
					"section .text at %d\n", head->symbol, head->index);
				exit(-1);
			}

			ei.f.imm = (unsigned int)refval;
		} 
		text[head->index] = ei.data;
		head = head->next;
	}
}

int main(int argc, char *argv[])
{
	FILE *f_out = NULL;
	yyin = fopen(argv[1], "r");

	if (argc > 2) {
		if(!strcmp("-o", argv[2] ) && argc > 3)
			f_out = fopen(argv[3], "wb");
		else {
			fprintf(stderr, "Usage: as <input file> -o <output_file>");
			exit(-1);
		}
	}

	symbols= ht_create(999);
	yyparse();
	
	link();

	if (!f_out)
		f_out = fopen("raw.out", "wb");
	fwrite(text, current , sizeof(unsigned int), f_out);
	fclose(yyin);
	fclose(f_out);
	return 0;
}
