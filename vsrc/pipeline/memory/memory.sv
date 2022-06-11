`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/memory/readdata.sv"
`include "pipeline/memory/writedata.sv"
`endif

module memory
    import pipes::*;
    import common::*;(
    input execute_data_t dataE,
    output memory_data_t dataM,

    input dbus_resp_t dresp,
    output dbus_req_t dreq,
    output u1 sctlM,
    input logic stall
);
    strobe_t strobe;
    u1 Werror, Rerror;

    assign dataM.valid = dataE.valid;
    assign dataM.raw_instr = dataE.raw_instr;
    assign dataM.dst = dataE.dst;
    assign dataM.regwrite = dataE.regwrite;
    assign dataM.memtoreg = dataE.memtoreg;
    assign dataM.pc = dataE.pc;
    assign dataM.aluout = dataE.aluout;
    assign dataM.skip = (dataE.memtoreg | dataE.memwrite) & (dataE.aluout[31]==0);

    assign dreq.valid = (dataE.memtoreg | dataE.memwrite) & ~dataE.csr.error & ~(Rerror | Werror) & ~stall;
    assign dreq.addr = dataE.aluout;
    assign dreq.size = dataE.msize;
    assign sctlM = dreq.valid && ~dresp.data_ok;


    always_comb begin
        if(dataE.memwrite) dreq.strobe = strobe;
        else dreq.strobe = '0;
    end

    always_comb begin
        dataM.csr = dataE.csr;
        if(!dataE.csr.error) begin
            if(dataE.memtoreg & Rerror) begin
                dataM.csr.error = 1;
                dataM.csr.code = 4;
            end else if(dataE.memwrite & Werror) begin
                dataM.csr.error = 1;
                dataM.csr.code = 6;
            end
        end
    end

    readdata readdata(
        ._rd(dresp.data),
        .rd(dataM.readdata),
        .addr(dataE.aluout[2:0]),
        .msize(dataE.msize),
        .mem_unsigned(dataE.mem_unsigned),
        .error(Rerror)
    );


    writedata writedata(
        .addr(dataE.aluout[2:0]),
        ._wd(dataE.writedata),
        .msize(dataE.msize),
        .wd(dreq.data),
        .strobe,
        .error(Werror)
    );

    
endmodule
`endif