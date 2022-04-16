`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module writeback
    import pipes::*;
    import common::*;(
    input memory_data_t dataM,
    output writeback_data_t dataW
);

    assign dataW.skip = dataM.skip;
    assign dataW.valid = dataM.valid;
    assign dataW.raw_instr = dataM.raw_instr;
    assign dataW.pc = dataM.pc;
    assign dataW.dst = dataM.dst;
    assign dataW.regwrite = dataM.regwrite;

    always_comb begin
        if(dataM.memtoreg) dataW.wdata = dataM.readdata;
        else dataW.wdata = dataM.aluout;
    end

endmodule

`endif