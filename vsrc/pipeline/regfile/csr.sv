`ifndef __CSR_SV
`define __CSR_SV


`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else
`include "csr_pkg.sv"
`endif

module csr
	import pipes::*;
	import common::*;
	import csr_pkg::*;(
	input logic clk, reset,
	input csr_addr_t ra,
	output word_t rd,
	input csr_t csr,
	input addr_t pc,
	input logic trint, swint, exint,
	output u2 mode,
	output logic interrupt,
	input logic stall,
	output addr_t PCselect
);
	csr_regs_t regs, regs_nxt;
	u2 mode_nxt;

	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
			mode <= 2'b11;
		end else if(~stall) begin
			regs <= regs_nxt;
			mode <= mode_nxt;
		end
	end

	always_comb begin
		if(regs.mstatus.mie)begin
			unique case (mode)
				2'b01: interrupt = (regs.mie[1]&swint) | (regs.mie[5]&trint) | (regs.mie[9]&exint);
				2'b11: interrupt = (regs.mie[3]&swint) | (regs.mie[7]&trint) | (regs.mie[11]&exint);
				default: interrupt = (regs.mie[3]&swint) | (regs.mie[7]&trint) | (regs.mie[11]&exint);
			endcase
		end
		else interrupt = 0;
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
		PCselect = pc + 4;
		// Writeback: W stage
		if (interrupt && ~stall && pc!=0) begin
			mode_nxt = 2'b11;
			regs_nxt.mepc = pc;
			PCselect = regs.mtvec;
			regs_nxt.mstatus.mpie = regs.mstatus.mie;
			regs_nxt.mstatus.mie = 0;
			regs_nxt.mstatus.mpp = mode;
			regs_nxt.mcause[XLEN-1] = 1;
			unique case (mode)
				2'b01: begin
					if(swint) regs_nxt.mcause[XLEN-2:0] = 1;
					else if(trint) regs_nxt.mcause[XLEN-2:0] = 5;
					else if(exint) regs_nxt.mcause[XLEN-2:0] = 9;
				end
				2'b11: begin
					if(swint) regs_nxt.mcause[XLEN-2:0] = 3;
					else if(trint) regs_nxt.mcause[XLEN-2:0] = 7;
					else if(exint) regs_nxt.mcause[XLEN-2:0] = 11;
				end
				default: begin
					if(swint) regs_nxt.mcause[XLEN-2:0] = 3;
					else if(trint) regs_nxt.mcause[XLEN-2:0] = 7;
					else if(exint) regs_nxt.mcause[XLEN-2:0] = 11;
				end
			endcase
		end else if (csr.wvalid) begin
			unique case(csr.wa)
				CSR_MIE: regs_nxt.mie = csr.wd;
				CSR_MIP:  regs_nxt.mip = csr.wd;
				CSR_MTVEC: regs_nxt.mtvec = csr.wd;
				CSR_MSTATUS: regs_nxt.mstatus = csr.wd;
				CSR_MSCRATCH: regs_nxt.mscratch = csr.wd;
				CSR_MEPC: regs_nxt.mepc = csr.wd;
				CSR_MCAUSE: regs_nxt.mcause = csr.wd;
				CSR_MCYCLE: regs_nxt.mcycle = csr.wd;
				CSR_MTVAL: regs_nxt.mtval = csr.wd;
				default: begin
					
				end
				
			endcase
			regs_nxt.mstatus.sd = regs_nxt.mstatus.fs != 0;
		end else if (csr.is_mret) begin
			PCselect = regs.mepc;
			regs_nxt.mstatus.mie = regs.mstatus.mpie;
			regs_nxt.mstatus.mpie = 1'b1;
			regs_nxt.mstatus.mpp = 2'b0;
			regs_nxt.mstatus.xs = 0;
			mode_nxt = regs.mstatus.mpp;
		end else if (csr.error) begin
			mode_nxt = 2'b11;
			regs_nxt.mepc = pc;
			PCselect = regs.mtvec;
			regs_nxt.mstatus.mpie = regs.mstatus.mie;
			regs_nxt.mstatus.mie = 0;
			regs_nxt.mstatus.mpp = mode;
			regs_nxt.mcause[XLEN-1] = 0;
			regs_nxt.mcause[3:0] = csr.code;
		end
	end
	
	
endmodule

`endif