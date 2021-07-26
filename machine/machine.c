#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include "binary.h"

#define RUNNING		0
#define HALT		1

#define ARRAY_SIZE(arr)  (sizeof(arr)/sizeof((arr)[0]))

#define STATUS_EQUAL	2
#define STATUS_GT	1
#define STATUS_LT	0

struct flag_fields {
	WORD gt_lt : 1;		/* if greater then, this flag is raised */
	WORD eq : 1;		/* if equal this flag is raised */
};

union status_register {
	WORD data;
	struct flag_fields bits;
};

struct Machine {
	/* general purpose registers */
	DWORD R[16];

	/* following registers are unaccessible from code */
	/* status register; for now only 2 bits are used 
	 * for indicating results of cmp instruction */
	union status_register ST;	

	/* instruction pointer */
	DWORD IP;

	/* random access memory. It is shared between code and data (Von Neumann) */
	DWORD memory[256]; 
};

typedef void (*BINARY_OPERATOR)(struct Machine *, DWORD *, DWORD);
typedef void (*UNARY_OPERATOR)(struct Machine *, DWORD *);

static void mov(struct Machine *m, DWORD *dst, DWORD src)
{
	*dst = src;
}
static void add(struct Machine *m, DWORD *dst, DWORD src)
{
	*dst += src;
}

static void sub(struct Machine *m, DWORD *dst, DWORD src) 
{
	*dst -= src;
}

static void or(struct Machine *m, DWORD *dst, DWORD src)
{
	*dst |= src;
}

static void and(struct Machine *m, DWORD *dst, DWORD src)
{
	*dst &= src;
}

static void xor(struct Machine *m, DWORD *dst, DWORD src)
{
	*dst ^= src;
}

static void outb(struct Machine *m, DWORD *src, DWORD x)
{
	putchar(*src);
}

static void inw(struct Machine *m, DWORD *dst, DWORD x)
{
	char tmp;
	tmp = getchar();
	*dst = atoi(&tmp);
}

static void outw(struct Machine *m, DWORD *dst, DWORD src)
{
	printf("%d\n", src);
}

static void shr(struct Machine *m, DWORD *dst, DWORD src)
{
	*dst = *dst >> src; 
}

static void shl(struct Machine *m, DWORD *dst, DWORD  src)
{
	*dst = *dst << src;
}

void do_instruction(struct Machine *m, union encoded_instr c, BINARY_OPERATOR op2)
{
	BYTE prefix = c.fields.prefix;
	BYTE rs = c.fields.rs;
	BYTE rd = c.fields.rd;
	WORD imm = c.fields.imm;
	DWORD imm2 = imm;
		
	switch(prefix) {
		case FORMAT_PREFIX_R: op2(m, &m->R[rd], m->R[rs]); break;
		case FORMAT_PREFIX_I: op2(m, &m->R[rd], imm); break; 
		case FORMAT_PREFIX_RM: op2(m, &m->R[rd], m->memory[imm]); break;
		case FORMAT_PREFIX_MR: op2(m, &m->memory[imm], m->R[rs]); break;
	}
}

int execute(struct Machine *m)
{
	int is_jmp = 0;
	char input = '\0';
	union encoded_instr current;
	REGISTER ip = m->IP;
	current.data =  m->memory[ip];
	BYTE opcode = current.fields.opcode;
	printf("instruction: 0x%x\n", current);
	switch(opcode) {
		case LDW: do_instruction(m, current, mov); break;
		case STW: do_instruction(m, current, mov); break;
		case MV:  do_instruction(m, current, mov); break;
		case ADD: do_instruction(m, current, add); break;
		case SUB: do_instruction(m, current, sub); break;
		case SHR: do_instruction(m, current, shr); break;
		case SHL: do_instruction(m, current, shl); break;
		case AND: do_instruction(m, current, and); break;
		case OR: do_instruction(m, current, or); break;
		case XOR: do_instruction(m, current, xor); break;
		case INW: do_instruction(m, current, inw); break;
		case OUTW: do_instruction(m, current, outw); break;
		/* single opcodes */
		case HLT: return HALT; break;
		case NOP: break;
		default: printf("not yet implemented\n");
	}

	/* if current instruction is not a jump, fetch next instruction */
	if (!is_jmp)
		m->IP++;	

	return RUNNING;
}

int load_program(struct Machine *m, char *progpath)
{
	int size = 0;
	FILE *fp = fopen(progpath, "rb");
	if (!fp) {
		fprintf(stderr, "Error! File \"%s\" doesn't exist!", progpath);
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
