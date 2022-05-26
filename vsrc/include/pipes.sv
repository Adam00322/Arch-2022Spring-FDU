`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv" 
`endif

package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter F7_ADDI = 7'b0010011;//XORI,ORI,ANDI,SLTI,SLTIU,SLLI,SRLI,SRAI
parameter F7_ADDIW = 7'b0011011;//f3 same as ADDI
parameter F7_LUI = 7'b0110111;//no f3
parameter F7_JAL = 7'b1101111;//no f3
parameter F7_BEQ = 7'b1100011;//BNE,BLT,BGE,BLTU,BGEU
parameter F7_LD = 7'b0000011;//LB,LH,LW
parameter F7_SD = 7'b0100011;
parameter F7_ADD = 7'b0110011;//SUB,AND,OR,XOR,SLL,MUL,DIV,DIVU,REM,REMU
parameter F7_ADDW = 7'b0111011;//f3 same as ADD
parameter F7_AUIPC = 7'b0010111;//no f3
parameter F7_JALR = 7'b1100111;


parameter F3_ADDI = 3'b000;
parameter F3_XORI = 3'b100;
parameter F3_ORI = 3'b110;
parameter F3_ANDI = 3'b111;
parameter F3_SLTI = 3'b010;
parameter F3_SLTIU = 3'b011;
parameter F3_SLLI = 3'b001;//f6
parameter F3_SRLI = 3'b101;//f6,SRAI

parameter F3_BEQ = 3'b000;
parameter F3_BNE = 3'b001;
parameter F3_BLT = 3'b100;
parameter F3_BLTU = 3'b110;
parameter F3_BGE = 3'b101;
parameter F3_BGEU = 3'b111;

parameter F3_LB = 3'b000;
parameter F3_LH = 3'b001;
parameter F3_LW = 3'b010;
parameter F3_LD = 3'b011;
parameter F3_LBU = 3'b100;
parameter F3_LHU = 3'b101;
parameter F3_LWU = 3'b110;

parameter F3_SB = 3'b000;
parameter F3_SH = 3'b001;
parameter F3_SW = 3'b010;
parameter F3_SD = 3'b011;

parameter F3_ADD = 3'b000;//SUB,MUL
// parameter F3_SUB = 3'b000;
parameter F3_AND = 3'b111;//REMU
parameter F3_OR = 3'b110;//REM
parameter F3_XOR = 3'b100;//DIV
parameter F3_SLL = 3'b001;
parameter F3_SLT = 3'b010;
parameter F3_SLTU = 3'b011;
parameter F3_SRL = 3'b101;//SRA,DIVU

parameter F3_JALR = 3'b000;


parameter F7_ADD_2 = 7'b0000000;
parameter F7_SUB_2 = 7'b0100000;
parameter F7_MUL_2 = 7'b0000001;

parameter F7_AND_2 = 7'b0000000;
parameter F7_REMU_2 = 7'b0000001;

parameter F7_OR_2 = 7'b0000000;
parameter F7_REM_2 = 7'b0000001;

parameter F7_XOR_2 = 7'b0000000;
parameter F7_DIV_2 = 7'b0000001;

parameter F7_SLL_2 = 7'b0000000;
parameter F7_SLT_2 = 7'b0000000;
parameter F7_SLTU_2 = 7'b0000000;

parameter F7_SRL_2 = 7'b0000000;
parameter F7_SRA_2 = 7'b0100000;
parameter F7_DIVU_2 = 7'b0000001;


parameter F6_SLLI = 6'b000000;
parameter F6_SRLI = 6'b000000;
parameter F6_SRAI = 6'b010000;



/* Define pipeline structures here */

typedef enum logic [4:0] {
	NULL,
    ALU_ADD,
    ALU_SUB,
    ALU_XOR,
    ALU_OR,
    ALU_AND,
    ALU_SLT,
    ALU_SLTU,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_ADDW,
    ALU_SUBW,
    ALU_SLLW,
    ALU_SRLW,
    ALU_SRAW,
    ALU_MUL,
    ALU_DIV,
    ALU_REM,
    ALU_DIVU,
    ALU_REMU,
    ALU_MULW,
    ALU_DIVW,
    ALU_REMW,
    ALU_DIVUW,
    ALU_REMUW
} alufunc_t;

typedef enum logic[7:0] {
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
    OP_JALR,
    OP_BNE,
    OP_BLT,
    OP_BGE,
    OP_BLTU,
    OP_BGEU,
    OP_SLTI,
    OP_SLTIU,
    OP_SLLI,
    OP_SRLI,
    OP_SRAI,
    OP_SLL,
    OP_SLT,
    OP_SLTU,
    OP_SRL,
    OP_SRA,
    OP_ADDIW,
    OP_SLLIW,
    OP_SRLIW,
    OP_SRAIW,
    OP_ADDW,
    OP_SUBW,
    OP_SLLW,
    OP_SRLW,
    OP_SRAW,
    OP_LB,
    OP_LH,
    OP_LW,
    OP_LBU,
    OP_LHU,
    OP_LWU,
    OP_SB,
    OP_SH,
    OP_SW,
    OP_MUL,
    OP_DIV,
    OP_REM,
    OP_DIVU,
    OP_REMU,
    OP_MULW,
    OP_DIVW,
    OP_REMW,
    OP_DIVUW,
    OP_REMUW
} decode_op_t;

typedef struct packed {
    u1 regwrite;
    alufunc_t alufunc;
    u1 alusrc;
    u1 memread;// the same as memtoreg
    u1 memwrite;
    u1 memtoreg;
    u1 mem_unsigned;
    msize_t msize;
} control_t;

typedef enum logic[4:0] {
    I_NULL,
    I_ADDI,
    I_SD,
    I_LUI,
    I_JAL,
    I_BEQ,
    I_AUIPC,
    I_JALR,
    I_SLLI
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
    u1 mem_unsigned;
	u32 raw_instr;
	addr_t pc;
    word_t aluout;
    word_t writedata;
    creg_addr_t dst;
    msize_t msize;
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
