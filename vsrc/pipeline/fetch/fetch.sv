`ifndef  __FETCH_SV
`define __FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/pcselect.sv"
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
    input u1 en
);

    addr_t pc, pc_nxt;
	assign ireq.addr = pc;
    always_ff @(posedge clk) begin
        if(en)begin
            if(reset) begin
                pc <= 64'h8000_0000;
            end else begin
                pc <= pc_nxt;
            end
        end
    end
    
    always_comb begin
        if(branch) begin
            pc_nxt = PCbranch;
        end else begin
            pc_nxt = pc+4;
        end
    end

    // pcselect pcselect(
    //     .pcplus4(pc+4),
	// 	.branch,
	// 	.PCbranch,
    //     .pc_selected(pc_nxt)
    // );

    assign dataF.valid = 1;
    assign dataF.raw_instr = iresp.data;
    assign dataF.pc = pc;
    
endmodule


`endif