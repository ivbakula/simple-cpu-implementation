#ifndef BINARY_H 
#define BINARY_H 

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef DWORD REGISTER;

typedef enum { R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, RA, RB, RC, RD, SP, BP} REGS;

/*
 * Instruction encoding schemes 
 * Format register-register:
 * ----------------------------
 * |Prefix | Opcode | Rd | Rs |
 * ----------------------------
 *		prefix - 2 bits
 *		opcode - 6 bits
 *		rd (destination register) - 4 bits
 *		rs (source register) - 4 bits
 *
 * Format register-immidiate:
 * ------------------------------
 * | prefix | opcode | rd | imm |
 * ------------------------------
 *		prefix - 2 bits
 *		opcode - 6 bits
 *		rd  - 4 bits
 *		imm (constant) - 20 bit
 *
 * format register-memory:
 * -------------------------------
 * | prefix | opcode | rd | mem  | 
 * -------------------------------
 *		 mem - 20 bit memory address
 *
 * format memory-register:
 * -----------------------------
 * | prefix| opcode | mem | rd |
 * -----------------------------
 *
 *
 * */

struct instruction_fields {
	DWORD imm : 16;
	DWORD rd : 4;
	DWORD rs : 4;
	DWORD opcode : 6;
	DWORD prefix : 2;
};

union encoded_instr {
	DWORD data;			/* instruction is one dword in size 32bit aligned little endian */
	struct instruction_fields fields;
};
						/* format dst-src */
#define FORMAT_PREFIX_R		0x0		/* format register-register */
#define FORMAT_PREFIX_MR	0x1		/* format memory-register */
#define FORMAT_PREFIX_RM	0x2		/* format register-memory */
#define FORMAT_PREFIX_I		0x3		/* format register-immidiate */

typedef enum { NOP, AND, OR, XOR, MOV, ADD, SUB, JT, JMP, EQ, GE, LE, GT, LT, HLT, OUTW } opcodes;

#endif
