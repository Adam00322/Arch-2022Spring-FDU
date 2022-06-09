`ifndef __CSR_SV
`define __CSR_SV


`ifdef VERILATOR
`include "include/csr_pkg.sv"
`else
`include "csr_pkg.sv"
`endif

module csr
	import common::*;
	import csr_pkg::*;(
	input logic clk, reset,
	input csr_addr_t ra,
	output word_t rd,
	input logic wvalid,
	input csr_addr_t wa,
	input word_t wd,
	input logic is_mret,
	input logic error,
	output addr_t pcselect
	

);
	csr_regs_t regs, regs_nxt;
	u2 mode, mode_nxt;

	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
			mode <= 2'b11;
		end else begin
			regs <= regs_nxt;
			mode <= mode_nxt;
		end
	end

	// read
	always_comb begin
		rd = '0;
		unique case(ra)
			CSR_MIE: rd = regs.mie;
			CSR_MIP: rd = regs.mip;
			CSR_MTVEC: rd = regs.mtvec;
			CSR_MSTATUS: rd = regs.mstatus;
			CSR_MSCRATCH: rd = regs.mscratch;
			CSR_MEPC: rd = regs.mepc;
			CSR_MCAUSE: rd = regs.mcause;
			CSR_MCYCLE: rd = regs.mcycle;
			CSR_MTVAL: rd = regs.mtval;
			default: begin
				rd = '0;
			end
		endcase
	end

	// write
	always_comb begin
		regs_nxt = regs;
		regs_nxt.mcycle = regs.mcycle + 1;
		mode_nxt = mode;
		// Writeback: W stage
		unique if (wvalid) begin
			unique case(wa)
				CSR_MIE: regs_nxt.mie = wd;
				CSR_MIP:  regs_nxt.mip = wd;
				CSR_MTVEC: regs_nxt.mtvec = wd;
				CSR_MSTATUS: regs_nxt.mstatus = wd;
				CSR_MSCRATCH: regs_nxt.mscratch = wd;
				CSR_MEPC: regs_nxt.mepc = wd;
				CSR_MCAUSE: regs_nxt.mcause = wd;
				CSR_MCYCLE: regs_nxt.mcycle = wd;
				CSR_MTVAL: regs_nxt.mtval = wd;
				default: begin
					
				end
				
			endcase
			regs_nxt.mstatus.sd = regs_nxt.mstatus.fs != 0;
		end else if (is_mret) begin
			regs_nxt.mstatus.mie = regs_nxt.mstatus.mpie;
			regs_nxt.mstatus.mpie = 1'b1;
			regs_nxt.mstatus.mpp = 2'b0;
			regs_nxt.mstatus.xs = 0;
			mode_nxt = regs.mstatus.mpp;
		end
		else begin

		end
	end
	assign pcselect = regs.mepc;
	
	
endmodule

`endif