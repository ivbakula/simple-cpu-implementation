#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include "binary.h"

#define RUNNING		0
#define HALT		1

#define ARRAY_SIZE(arr)  (sizeof(arr)/sizeof((arr)[0]))

struct Machine {
	/* general purpose registers */
	DWORD R[16];

	/* following registers are unaccessible from code */
	DWORD ST;	/* status register */

	/* instruction pointer */
	DWORD IP;

	DWORD memory[256];
};

typedef void (*BINARY_OPERATOR)(DWORD *, DWORD);
typedef void (*UNARY_OPERATOR)(DWORD *);

static void mov(DWORD *dst, DWORD src)
{
	*dst = src;
}
static void add(DWORD *dst, DWORD src)
{
	*dst += src;
}

static void sub(DWORD *dst, DWORD src) 
{
	*dst -= src;
}

static void or(DWORD *dst, DWORD src)
{
	*dst |= src;
}

static void and(DWORD *dst, DWORD src)
{
	*dst &= src;
}

static void xor(DWORD *dst, DWORD src)
{
	*dst ^= src;
}

void do_instruction_binary(struct Machine *m, union encoded_instr c, BINARY_OPERATOR op)
{
	BYTE prefix = c.fields.prefix;
	BYTE rs = c.fields.rs;
	BYTE rd = c.fields.rd;
	WORD imm = c.fields.imm;

	switch(prefix) {
		case FORMAT_PREFIX_R: op(&m->R[rd], m->R[rs]); break;
		case FORMAT_PREFIX_I: op(&m->R[rd], imm); break; 
		case FORMAT_PREFIX_RM: op(&m->R[rd], m->memory[imm]); break;
		case FORMAT_PREFIX_MR: op(&m->memory[imm], m->R[rs]); break;
	}
}

int execute(struct Machine *m)
{
	union encoded_instr current;
	REGISTER ip = m->IP;
	current.data =  m->memory[ip];
	
	BYTE opcode = current.fields.opcode;
	switch(opcode) {
		case MOV: do_instruction_binary(m, current, &mov); break;
		case ADD: do_instruction_binary(m, current, &add); break;
		case SUB: do_instruction_binary(m, current, &sub); break;
		case OR: do_instruction_binary(m, current, &or); break;
		case AND: do_instruction_binary(m, current, &and); break;
		case XOR: do_instruction_binary(m, current, &xor); break;
		case HLT: return HALT; break;
		case NOP: break;
		case OUTW: printf("%d\n", m->R[0]); break;
		default: printf("not yet implemented\n");
	}

	m->IP++;	/* fetch new instruction */
	return RUNNING;
}

int load_program(struct Machine *m, char *progpath)
{
	int size = 0;
	FILE *fp = fopen(progpath, "rb");
	if (!fp) {
		fprintf(stderr, "Error! Program \"%s\"doesn't exist!", progpath);
		return -1;
	}
	size = fread(m->memory, sizeof(*m->memory), ARRAY_SIZE(m->memory), fp);
	fclose(fp);

	return size;
}

int main(int argc, char *argv[]) 
{
	struct Machine m;
	int retval = 0;
	int status = RUNNING;
	memset(&m, '\0', sizeof(m));

	if (argc < 2) {
	    fprintf(stderr, "Error! No program to execute\n");
	    exit(-1);
	}

	retval = load_program(&m, argv[1]);
	if (retval == 0) {
		fprintf(stderr, "Error! Program not loaded\n");
		return(-1);
	}

	if (retval < 0)
		return -1;

	while (status == RUNNING)
		status = execute(&m);

	return 0;
}
