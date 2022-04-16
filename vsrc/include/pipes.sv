`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv" 
`endif

package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter F7_ADDI = 7'b0010011;//XORI,ORI,ANDI
// parameter F7_XORI = 7'b0010011;
// parameter F7_ORI = 7'b0010011;
// parameter F7_ANDI = 7'b0010011;
parameter F7_LUI = 7'b0110111;//no f3
parameter F7_JAL = 7'b1101111;//no f3
parameter F7_BEQ = 7'b1100011;
parameter F7_LD = 7'b0000011;
parameter F7_SD = 7'b0100011;
parameter F7_ADD = 7'b0110011;//SUB,AND,OR,XOR  f7_2
// parameter F7_SUB = 7'b0110011;
// parameter F7_AND = 7'b0110011;
// parameter F7_OR = 7'b0110011;
// parameter F7_XOR = 7'b0110011;
parameter F7_AUIPC = 7'b0010111;//no f3
parameter F7_JALR = 7'b1100111;

parameter F3_ADDI = 3'b000;
parameter F3_XORI = 3'b100;
parameter F3_ORI = 3'b110;
parameter F3_ANDI = 3'b111;
parameter F3_BEQ = 3'b000;
parameter F3_LD = 3'b011;
parameter F3_SD = 3'b011;
parameter F3_ADD = 3'b000;//SUB
// parameter F3_SUB = 3'b000;
parameter F3_AND = 3'b111;
parameter F3_OR = 3'b110;
parameter F3_XOR = 3'b100;
parameter F3_JALR = 3'b000;

parameter F7_ADD_2 = 7'b0000000;
parameter F7_SUB_2 = 7'b0100000;
parameter F7_AND_2 = 7'b0000000;
parameter F7_OR_2 = 7'b0000000;
parameter F7_XOR_2 = 7'b0000000;



/* Define pipeline structures here */

typedef enum logic [4:0] {
	NULL,
    ALU_ADD,
    ALU_SUB,
    ALU_XOR,
    ALU_OR,
    ALU_AND
} alufunc_t;

typedef enum logic[5:0] {
    UNKNOWN,
	OP_ADDI,
    OP_XORI,
    OP_ORI,
    OP_ANDI,
    OP_LUI,
    OP_JAL,
    OP_BEQ,
    OP_LD,
    OP_SD,
    OP_ADD,
    OP_SUB,
    OP_AND,
    OP_OR,
    OP_XOR,
    OP_AUIPC,
    OP_JALR
} decode_op_t;

typedef struct packed {
    u1 regwrite;
    alufunc_t alufunc;
    u1 alusrc;
    u1 memread;// the same as memtoreg
    u1 memwrite;
    u1 memtoreg;
} control_t;

typedef enum logic[4:0] {
    I_NULL,
    I_ADDI,
    I_SD,
    I_LUI,
    I_JAL,
    I_BEQ,
    I_AUIPC,
    I_JALR
} im_t;

typedef struct packed {
    u1 valid;
	u32 raw_instr;
	addr_t pc;
} fetch_data_t;

typedef struct packed {
    u1 valid;
    u32 raw_instr;
	addr_t pc;
    word_t srca,srcb,imm;
	control_t ctl;
    creg_addr_t dst;
    creg_addr_t ra1,ra2;
} decode_data_t;

typedef struct packed {
    u1 valid;
    u1 regwrite;
    u1 memtoreg;
    u1 memread;
    u1 memwrite;
	u32 raw_instr;
	addr_t pc;
    word_t aluout;
    word_t writedata;
    creg_addr_t dst;
} execute_data_t;

typedef struct packed {
    u1 valid;
	u32 raw_instr;
	addr_t pc;
    u1 regwrite;
    u1 memtoreg;
    word_t readdata;
    word_t aluout;
    creg_addr_t dst;
    u1 skip;
} memory_data_t;

typedef struct packed {
    u1 skip;
    u1 valid;
    u32 raw_instr;
	addr_t pc;
    u1 regwrite;
    word_t wdata;
    creg_addr_t dst;
} writeback_data_t;

typedef enum logic[3:0] {
    RD,
    ALUOUTE,
    ALUOUTM,
    MEMDATA,
    WDATA
} src_t;
typedef struct packed {
    u1 stall;
    src_t ac;
    src_t bc;
} supercontrol_t;

endpackage
`endif
