`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/writeback/writeback.sv"
`include "pipeline/supercontrol/supercontrol.sv"

`else
`endif

module core 
	import common::*;
	import pipes::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp
);
	/* TODO: Add your pipeline here. */
	
	
	fetch_data_t dataF, dataF_nxt;
	decode_data_t dataD, dataD_nxt;
	execute_data_t dataE, dataE_nxt;
	memory_data_t dataM, dataM_nxt;
	writeback_data_t dataW;
	supercontrol_t sctlD, sctlE;

	creg_addr_t ra1, ra2;
	word_t rd1, rd2;
	addr_t PCbranch_nxt;
	addr_t PCbranch;
	decode_op_t op;
	u1 branch_nxt;
	u1 branch;
	u1 sctlF;
	u1 stallF;
	u1 stallD;
	u1 stallE;
	u1 stallM;

	assign stallF = sctlF | stallD;
	assign stallD = sctlD.stall | stallE;
	assign stallE = sctlE.stall | stallM;

	fetch fetch(
		.clk,.reset,
		.ireq,
		.iresp,
		.dataF(dataF_nxt),
		.branch,
		.PCbranch,
		.en(~stallF),
		.sctlF
	);
	
	always_ff @(posedge clk) begin
		if(reset) branch <= 0;
		else if(branch_nxt) begin
			branch <= 1;
			PCbranch <= PCbranch_nxt;
		end
	end

	always_ff @(posedge clk) begin
		if(~stallD) begin
			if(reset | stallF) dataF <= '0;
			else if(branch)begin
				dataF <= '0;
				branch <= 0;
			end
			else dataF <= dataF_nxt;
		end	
	end
	
	decode decode(
		.dataF,
		.dataD(dataD_nxt),
		.PCbranch(PCbranch_nxt),
		.branch(branch_nxt),
		.op,
		.rd1,.rd2,.ra1,.ra2,
		.aluoutE(dataE.aluout),
		.aluoutM(dataM.aluout),
		.memdata(dataM.readdata),
		.sctlD
	);

	always_ff @(posedge clk) begin
		if (~stallE) begin
			if(reset | stallD) dataD <= '0;
			else dataD <= dataD_nxt;
		end
	end

	execute execute(
		.dataD,
		.dataE(dataE_nxt),
		.aluoutE(dataE.aluout),
		.aluoutM(dataM.aluout),
		.memdata(dataM.readdata),
		.sctlE
	);

	always_ff @(posedge clk) begin
		if(~stallM) begin
			if(reset | stallE) dataE <= '0;
			else dataE <= dataE_nxt;
		end
	end

	memory memory(
		.dataE,
		.dataM(dataM_nxt),
		.dresp,
		.dreq,
		.stallM
	);

	always_ff @(posedge clk) begin
		if(reset | stallM) dataM <= '0;
		else dataM <= dataM_nxt;
	end

	writeback writeback(
		.dataM,
		.dataW
	);

	supercontrol supercontrol(
		.ra1,.ra2,
		.Dra1(dataD.ra1),
		.Dra2(dataD.ra2),
		.op,
		.dstD(dataD.dst),
		.dstE(dataE.dst),
		.dstM(dataM.dst),
		.memtoregD(dataD.ctl.memtoreg),
		.memtoregE(dataE.memtoreg),
		.memtoregM(dataM.memtoreg),
		.regwriteD(dataD.ctl.regwrite),
		.regwriteE(dataE.regwrite),
		.regwriteM(dataM.regwrite),
		.sctlD,
		.sctlE
	);

	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.wvalid(dataW.regwrite),
		.wa(dataW.dst),
		.wd(dataW.wdata)
	);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (dataW.valid),//无提交时�?0
		.pc                 (dataW.pc),
		.instr              (dataW.raw_instr),
		.skip               (dataW.skip),//内存读写时为1
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW.regwrite),
		.wdest              ({3'b0,dataW.dst}),
		.wdata              (dataW.wdata)
	);
	      
	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);
	      
	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);
	      
	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (0),
		.sstatus            (0),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	      );
	      
	DifftestArchFpRegState DifftestArchFpRegState(
		.clock              (clk),
		.coreid             (0),
		.fpr_0              (0),
		.fpr_1              (0),
		.fpr_2              (0),
		.fpr_3              (0),
		.fpr_4              (0),
		.fpr_5              (0),
		.fpr_6              (0),
		.fpr_7              (0),
		.fpr_8              (0),
		.fpr_9              (0),
		.fpr_10             (0),
		.fpr_11             (0),
		.fpr_12             (0),
		.fpr_13             (0),
		.fpr_14             (0),
		.fpr_15             (0),
		.fpr_16             (0),
		.fpr_17             (0),
		.fpr_18             (0),
		.fpr_19             (0),
		.fpr_20             (0),
		.fpr_21             (0),
		.fpr_22             (0),
		.fpr_23             (0),
		.fpr_24             (0),
		.fpr_25             (0),
		.fpr_26             (0),
		.fpr_27             (0),
		.fpr_28             (0),
		.fpr_29             (0),
		.fpr_30             (0),
		.fpr_31             (0)
	);
	
`endif
endmodule
`endif