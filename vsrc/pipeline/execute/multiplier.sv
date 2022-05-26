`ifndef __MULTIPLIER_SV
`define __MULTIPLIER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module multiplier
    import common::*;
	import pipes::*; (
    input logic clk, valid,
    input u64 a, b,
    output logic done,
    output u64 c // c = a * b
);
    enum i1 { INIT, DOING } state, state_nxt;
    i65 count, count_nxt;
    localparam MULT_DELAY = {1'b1, 64'b0};
    always_ff @(posedge clk) begin
        if (~valid) begin
            {state, count} <= '0;
        end else begin
            {state, count} <= {state_nxt, count_nxt};
        end
    end
    assign done = (state_nxt == INIT);
    always_comb begin
        {state_nxt, count_nxt} = {state, count};
        unique case(state)
            INIT: begin
                if (valid) begin
                    state_nxt = DOING;
                    count_nxt = MULT_DELAY;
                end
            end
            DOING: begin
                count_nxt = {1'b0, count_nxt[64:1]};
                if (count_nxt == '0) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    logic[128:0] p, p_nxt;
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {65'b0, a};
            end
            DOING: begin
                if (p_nxt[0]) begin
                    p_nxt[128:64] = p_nxt[128:64] + b;
            	end
            	p_nxt = {1'b0, p_nxt[128:1]};
            end
        endcase
    end
    always_ff @(posedge clk) begin
        if (~valid) begin
            p <= '0;
        end else begin
            p <= p_nxt;
        end
    end
    assign c = p[63:0];
endmodule

`endif
