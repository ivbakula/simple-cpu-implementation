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

static void cmp(struct Machine *m, DWORD *dst, DWORD src)
{
	/* reset complete status register including unused (for now) fields */
	m->ST.data = 0;	
	if (*dst > src) 
	    m->ST.data = STATUS_GT;
	else if ( *dst == src) 
	    m->ST.data = STATUS_EQUAL;  
	 else 
	    m->ST.data = STATUS_LT;
}

static void outb(struct Machine *m, DWORD *src)
{
	putchar(*src);
}

static void inb(struct Machine *m, DWORD *dst)
{
	*dst = getchar();
}

static void outl(struct Machine *m, DWORD *src)
{
	printf("%d\n", *src);
}

static void inl(struct Machine *m, DWORD *dst) 
{
	*dst = getchar();
}

static void not(struct Machine *m, DWORD *dst)
{
	*dst = ~(*dst);
}

static void inc(struct Machine *m, DWORD *dst)
{
	*dst++;
}

static void dec(struct Machine *m, DWORD *dst)
{
	*dst--;
}
static void jmp(struct Machine *m, DWORD *dst)
{
	m->IP = *dst;
}

static void jlt(struct Machine *m, DWORD *dst)
{
	if (m->ST.data == STATUS_LT) {
		m->IP = *dst;
	} else {
		m->IP++;
	}
}

static void jgt(struct Machine *m, DWORD *dst)
{
	if (m->ST.data == STATUS_GT) {
		jmp(m, dst);
	} else {
		m->IP++;
	}
}

static void jle(struct Machine *m, DWORD *dst)
{
	if (m->ST.data == STATUS_LT || m->ST.data == STATUS_EQUAL) {
		jmp(m, dst);
	} else {
		m->IP++;
	}
}

static void jge(struct Machine *m, DWORD *dst)
{
	if (m->ST.data == STATUS_GT || m->ST.data == STATUS_EQUAL) {
		jmp(m, dst);
	} else {
		m->IP++;
	}
}

static void je(struct Machine *m, DWORD *dst)
{
	if (m->ST.data == STATUS_EQUAL) {
		jmp(m, dst);
	} else {
		m->IP++;
	}
}

void do_instruction(struct Machine *m, union encoded_instr c, BINARY_OPERATOR op2, UNARY_OPERATOR op1)
{
	BYTE prefix = c.fields.prefix;
	BYTE rs = c.fields.rs;
	BYTE rd = c.fields.rd;
	WORD imm = c.fields.imm;
	DWORD imm2 = imm;
		
	if (op2) {
		switch(prefix) {
			case FORMAT_PREFIX_R: op2(m, &m->R[rd], m->R[rs]); break;
			case FORMAT_PREFIX_I: op2(m, &m->R[rd], imm); break; 
			case FORMAT_PREFIX_RM: op2(m, &m->R[rd], m->memory[imm]); break;
			case FORMAT_PREFIX_MR: op2(m, &m->memory[imm], m->R[rs]); break;
		}
	} else if (op1) {
		switch(prefix) {
			case FORMAT_PREFIX_R: op1(m, &m->R[rs]); break;
			case FORMAT_PREFIX_I: op1(m, &imm2); break; 
			case FORMAT_PREFIX_MR: op1(m, &m->memory[imm]); break;
		}
	} 
}

int execute(struct Machine *m)
{
	int is_jmp = 0;
	union encoded_instr current;
	REGISTER ip = m->IP;
	current.data =  m->memory[ip];
	BYTE opcode = current.fields.opcode;

	switch(opcode) {
		/* unary operators (only on registers) */
		case NOT: break;
		case INC: break; 
		case DEC: printf("not implemented yet\n"); return HALT; break;

		case OUTB: do_instruction(m, current, NULL, &outb); break;
		case OUTL: do_instruction(m, current, NULL, &outl); break;
		case INB: do_instruction(m, current, NULL, &inb); break;
		case INL: do_instruction(m, current, NULL, &inl); break;

		/* binary operators */
		case MOV: do_instruction(m, current, &mov, NULL); break;
		case ADD: do_instruction(m, current, &add, NULL); break;
		case SUB: do_instruction(m, current, &sub, NULL); break;
		case OR: do_instruction(m, current, &or, NULL); break;
		case AND: do_instruction(m, current, &and, NULL); break;
		case XOR: do_instruction(m, current, &xor, NULL); break;
		case CMP: do_instruction(m, current, &cmp, NULL); break;

		/* jumps */
		case JMP: do_instruction(m, current, NULL, &jmp); is_jmp = 1; break;
		case JLT: do_instruction(m, current, NULL, &jlt); is_jmp = 1; break;
		case JGT: do_instruction(m, current, NULL, &jgt); is_jmp = 1; break;
		case JLE: do_instruction(m, current, NULL, &jle); is_jmp = 1; break;
		case JGE: do_instruction(m, current, NULL, &jge); is_jmp = 1; break;
		case JE: do_instruction(m, current,  NULL, &je);  is_jmp = 1; break;

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
