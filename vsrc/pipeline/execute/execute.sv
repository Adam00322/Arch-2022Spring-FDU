`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`endif

module execute
    import common::*;
    import pipes::*;(
    input decode_data_t dataD,
    output execute_data_t dataE,

    input word_t aluoutE,
    input word_t aluoutM,
    input word_t memdata,
    input supercontrol_t sctlE
);
    word_t a,b,tb;

    assign dataE.valid = dataD.valid;
    assign dataE.regwrite = dataD.ctl.regwrite;
    assign dataE.memtoreg = dataD.ctl.memtoreg;
    assign dataE.memread = dataD.ctl.memread;
    assign dataE.memwrite = dataD.ctl.memwrite;
    assign dataE.writedata = tb;
    assign dataE.pc = dataD.pc;
    assign dataE.raw_instr = dataD.raw_instr;
    assign dataE.dst = dataD.dst;
    assign dataE.msize = dataD.ctl.msize;
    assign dataE.mem_unsigned = dataD.ctl.mem_unsigned;

    always_comb begin
        unique case (sctlE.ac)
            RD: a = dataD.srca;
            ALUOUTE: a = aluoutE;
            ALUOUTM: a = aluoutM;
            MEMDATA: a = memdata;
            default: a = dataD.srca;
        endcase
    end

    always_comb begin
        unique case (sctlE.bc)
            RD: tb = dataD.srcb;
            ALUOUTE: tb = aluoutE;
            ALUOUTM: tb = aluoutM;
            MEMDATA: tb = memdata;
            default: tb = dataD.srcb;
        endcase
    end

    always_comb begin
        if(dataD.ctl.alusrc) b = dataD.imm;
        else  b = tb;
    end

    alu alu(
        .a,
        .b,
        .alufunc(dataD.ctl.alufunc),
        .c(dataE.aluout)
    );
    
endmodule

`endif