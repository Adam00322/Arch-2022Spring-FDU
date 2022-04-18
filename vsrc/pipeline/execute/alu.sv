`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module alu
	import common::*;
	import pipes::*; (
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 c
);
	always_comb begin
		c = '0;
		unique case(alufunc)
			NULL: c = b;
			ALU_ADD: c = a + b;
			ALU_SUB: c = a - b;
			ALU_XOR: c = a ^ b;
			ALU_OR:  c = a | b;
			ALU_AND: c = a & b;
			ALU_SLT: c = $signed(a) < $signed(b);
			ALU_SLTU: c = a < b;
			ALU_SLL: c = a << b[5:0];
			ALU_SRL: c = a >> b[5:0];
			ALU_SRA: c = $signed(a) >>> b[5:0];
			ALU_ADDW: begin c = a + b; c = {{32{c[31]}},c[31:0]}; end
			ALU_SUBW: begin c = a + b; c = {{32{c[31]}},c[31:0]}; end
			ALU_SLLW: begin c = a << b[4:0]; c = {{32{c[31]}},c[31:0]}; end
			ALU_SRLW: begin c = a >> b[4:0]; c = {{32{c[31]}},c[31:0]}; end
			ALU_SRAW: begin c = $signed(a) >>> b[4:0]; c = {{32{c[31]}},c[31:0]}; end
			default: c = '0;
		endcase
	end
	
endmodule

`endif
