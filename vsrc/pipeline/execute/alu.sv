`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/multiplier.sv"
`include "pipeline/execute/divider.sv"
`endif

module alu
	import common::*;
	import pipes::*; (
	input logic clk,
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 c,
	output u1 alustall,
	input logic stallE
);
	u1 mul, div, muldone, divdone;
	u64 absa, absb, mulout;
	u128 divout;

	assign alustall = (mul&~muldone) | (div&~divdone);

	always_comb begin
		absa = a;
		absb = b;
		mul = '0;
		div = '0;
		c = '0;
		unique case(alufunc)
			NULL: c = b;
			ALU_ADD: c = a + b;
			ALU_SUB: c = a - b;
			ALU_XOR: c = a ^ b;
			ALU_OR:  c = a | b;
			ALU_AND: c = a & b;
			ALU_SLT: c[0] = $signed(a) < $signed(b);
			ALU_SLTU: c[0] = a < b;
			ALU_SLL: c = a << b[5:0];
			ALU_SRL: c = a >> b[5:0];
			ALU_SRA: c = $signed(a) >>> b[5:0];
			ALU_ADDW: begin
				c = a + b;
				c = {{32{c[31]}},c[31:0]};
			end
			ALU_SUBW: begin
				c = a - b;
				c = {{32{c[31]}},c[31:0]};
			end
			ALU_SLLW: begin
				c[31:0] = a[31:0] << b[4:0];
				c = {{32{c[31]}},c[31:0]};
			end
			ALU_SRLW: begin
				c[31:0] = a[31:0] >> b[4:0];
				c = {{32{c[31]}},c[31:0]};
			end
			ALU_SRAW: begin
				c[31:0] = $signed(a[31:0]) >>> b[4:0];
				c = {{32{c[31]}},c[31:0]};
			end
			ALU_MUL: begin
				mul = 1;
				c = mulout;
			end
			ALU_DIV: begin
				if(b=='0) begin
					c = '1;
				end
				else begin
					div = 1;
					absa = (a[63])?(~a + 1'b1):a;
					absb = (b[63])?(~b + 1'b1):b;
					c = (a[63]^b[63])?(~divout[63:0] + 1'b1):divout[63:0];
				end
			end
			ALU_REM: begin
				if(b=='0) begin
					c = a;
				end
				else begin
					div = 1;
					absa = (a[63])?(~a + 1'b1):a;
					absb = (b[63])?(~b + 1'b1):b;
					c = (a[63])?(~divout[127:64] + 1'b1):divout[127:64];
				end
			end
			ALU_DIVU: begin
				if(b=='0) begin
					c = '1;
				end
				else begin
					div = 1;
					c = divout[63:0];
				end
			end
			ALU_REMU: begin
				if(b=='0) begin
					c = a;
				end
				else begin
					div = 1;
					c = divout[127:64];
				end
			end
			ALU_MULW: begin
				mul = 1;
				c = {{32{mulout[31]}},mulout[31:0]};
			end
			ALU_DIVW: begin
				if(b[31:0]=='0) begin
					c = '1;
				end
				else begin
					div = 1;
					absa = {32'b0,(a[31])?(~a[31:0] + 1'b1):a[31:0]};
					absb = {32'b0,(b[31])?(~b[31:0] + 1'b1):b[31:0]};
					c[31:0] = (a[31]^b[31])?(~divout[31:0] + 1'b1):divout[31:0];
					c = {{32{c[31]}},c[31:0]};
				end
			end
			ALU_REMW: begin
				if(b[31:0]=='0) begin
					c = {{32{a[31]}},a[31:0]};
				end
				else begin
					div = 1;
					absa = {32'b0,(a[31])?(~a[31:0] + 1'b1):a[31:0]};
					absb = {32'b0,(b[31])?(~b[31:0] + 1'b1):b[31:0]};
					c[31:0] = (a[31])?(~divout[95:64] + 1'b1):divout[95:64];
					c = {{32{c[31]}},c[31:0]};
				end
			end
			ALU_DIVUW: begin
				if(b[31:0]=='0) begin
					c = '1;
				end
				else begin
					absa = {32'b0,a[31:0]};
					absb = {32'b0,b[31:0]};
					div = 1;
					c = {{32{divout[31]}},divout[31:0]};
				end
			end
			ALU_REMUW: begin
				if(b[31:0]=='0) begin
					c = {{32{a[31]}},a[31:0]};
				end
				else begin
					absa = {32'b0,a[31:0]};
					absb = {32'b0,b[31:0]};
					div = 1;
					c = {{32{divout[95]}},divout[95:64]};
				end
			end
			default: c = '0;
		endcase
	end

	multiplier multiplier(
		.clk,
		.valid(mul&~stallE),
		.a(absa),
		.b(absb),
		.done(muldone),
		.c(mulout)
	);

	divider divider(
		.clk,
		.valid(div&~stallE),
		.a(absa),
		.b(absb),
		.done(divdone),
		.c(divout)
	);
	
endmodule

`endif
