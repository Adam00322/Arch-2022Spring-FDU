`ifndef  __FETCH_SV
`define __FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module fetch
    import pipes::*;
    import common::*;(

    input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
    output fetch_data_t dataF,
    input logic branch,
    input addr_t PCbranch,
    input logic flush,
    input addr_t PCselect,
    input u1 en,
    output u1 sctlF
);

    addr_t pc, pc_nxt;
	assign ireq.addr = pc;
    assign sctlF = ireq.valid && ~iresp.data_ok;

    always_ff @(posedge clk) begin
        if(reset) begin
            pc <= 64'h8000_0000;
        end
        else if(en | flush) begin
            pc <= pc_nxt;
        end
    end
    
    always_comb begin
        dataF.csr = '0;
        ireq.valid = 1;
        if(pc[0] | pc[1]) begin
            ireq.valid = 0;
            dataF.csr.error = 1;
            dataF.csr.code = 0;
        end
    end

    always_comb begin
        if (flush) begin
            pc_nxt = PCselect;
        end else if(branch) begin
            pc_nxt = PCbranch;
        end else begin
            pc_nxt = pc+4;
        end
    end

    assign dataF.valid = ireq.valid;
    assign dataF.raw_instr = iresp.data;
    assign dataF.pc = pc;
    
endmodule


`endif