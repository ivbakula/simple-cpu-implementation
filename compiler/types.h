#ifndef TYPES_H
#define TYPES_H

#define SECTION_TEXT	0
#define SECTION_DATA	1

#define INSTR_TYPE_A    0
#define INSTR_TYPE_B	1
#define INSTR_TYPE_C	2

#define FUNC_BLOCK_SPECIAL	0
#define FUNC_BLOCK_ALU		1
#define FUNC_BLOCK_DATA		2
#define FUNC_BLOCK_BRANCH	3
#define FUNC_BLOCK_IO		4


#define OPCODE_ADD	0
#define OPCODE_ADDI	1
#define OPCODE_SUB	2

#define RELAX_NONE	0
#define RELAX_PCREL	1
#define RELAX_ABS	2

#include <stdint.h>

typedef unsigned int DWORD;
struct regs {
    DWORD r1 : 4;
    DWORD r2 : 4;
    DWORD rd : 4;
};

union regfile {
    DWORD data;
    struct regs regs;
};

struct instr_dt_fields {
    union regfile regfile;
    DWORD imm;
};

struct instr_type_a {
	DWORD imm : 15;
	DWORD hi : 1;
	DWORD r1 : 4; 
	DWORD rd : 4;
	DWORD opcode : 3;
	DWORD type : 2;
	DWORD func : 3;
};

struct instr_type_b {
	DWORD imm : 11;
	DWORD r2 : 4;
	DWORD hi : 1;
	DWORD r1 : 4;
	DWORD rd : 4;
	DWORD opcode : 3;
	DWORD type : 2; 
	DWORD func : 3;
};

struct instr_type_c {
	DWORD imm : 21;
	DWORD rd : 4;
	DWORD opcode : 3;
	DWORD type : 2;
	DWORD func : 3;
};

union instr {
	DWORD data;
	struct instr_type_a A;
	struct instr_type_b B;
	struct instr_type_c C;
};

struct frag {
	union instr instr;
	uint8_t instr_type;
	uint8_t relax_type;
	bool reloc;
	const char *label;
	int label_addr;
//	struct frag *next;
};
#endif
