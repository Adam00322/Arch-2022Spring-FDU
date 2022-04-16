`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module memory
    import pipes::*;
    import common::*;(
    input execute_data_t dataE,
    output memory_data_t dataM,

    input dbus_resp_t dresp,
    output dbus_req_t dreq
);

    assign dataM.valid = dataE.valid;
    assign dataM.raw_instr = dataE.raw_instr;
    assign dataM.dst = dataE.dst;
    assign dataM.regwrite = dataE.regwrite;
    assign dataM.memtoreg = dataE.memtoreg;
    assign dataM.pc = dataE.pc;
    assign dataM.aluout = dataE.aluout;
    assign dataM.skip = (dataE.memtoreg | dataE.memwrite) & (dataE.aluout[31]==0);

    assign dreq.valid = dataE.memtoreg | dataE.memwrite;
    assign dreq.addr = dataE.aluout;
    assign dreq.size = MSIZE8;
    assign dreq.data = dataE.writedata;

    always_comb begin
        if(dataE.memwrite)dreq.strobe = 8'b11111111;
        else dreq.strobe = '0;
    end

    assign dataM.readdata = dresp.data;



    
endmodule
`endif