`ifndef __SUPERCONTROL_SV
`define __SUPERCONTROL_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module supercontrol
    import pipes::*;
    import common::*;(
    input creg_addr_t ra1, ra2,
    input creg_addr_t Dra1, Dra2,
    input decode_op_t op,
    input creg_addr_t dstD,dstE,dstM,
    input u1 memD, memtoregE, memtoregM, regwriteD, regwriteE, regwriteM,
    output supercontrol_t sctlD, sctlE
);
    u1 OP_B, Drelate, Erelate;
    assign OP_B = op == OP_BEQ || op == OP_JALR || op == OP_BNE || op == OP_BLT || op == OP_BLTU || op == OP_BGE || op == OP_BGEU;
    assign Drelate = regwriteD && (ra1 == dstD || ra2 == dstD);
    assign Erelate = memtoregE && (ra1 == dstE || ra2 == dstE);
    
    always_comb begin
        sctlD = '0;
        if((OP_B && (Drelate || Erelate)) || (Erelate && memD && dstD != dstE)) begin
            sctlD.stall = 1;
        end else begin
            sctlD.stall = 0;
            if(ra1 == 5'b00000) sctlD.ac = RD;
            else if(regwriteE && ra1 == dstE) begin
                sctlD.ac = ALUOUTE;
            end else if (regwriteM && ra1 == dstM) begin
                if (memtoregM) sctlD.ac = MEMDATA;
                else sctlD.ac = ALUOUTM;
            end else sctlD.ac = RD;
            if(ra2 == 5'b00000) sctlD.bc = RD;
            else if(regwriteE && ra2 == dstE) begin
                sctlD.bc = ALUOUTE;
            end else if (regwriteM && ra2 == dstM) begin
                if (memtoregM) sctlD.bc = MEMDATA;
                else sctlD.bc = ALUOUTM;
            end else sctlD.bc = RD;
        end
    end

    always_comb begin
        sctlE = '0;
        if(memtoregE && (Dra1 == dstE || Dra2 == dstE)) begin
            sctlE.stall = 1;
        end else begin
            sctlE.stall = 0;
            if(Dra1 == 5'b00000) sctlE.ac = RD;
            else if(regwriteE && Dra1 == dstE) begin
                sctlE.ac = ALUOUTE;
            end else if (regwriteM && Dra1 == dstM) begin
                if (memtoregM) sctlE.ac = MEMDATA;
                else sctlE.ac = ALUOUTM;
            end else sctlE.ac = RD;
            if(Dra2 == 5'b00000) sctlE.bc = RD;
            else if(regwriteE && Dra2 == dstE) begin
                sctlE.bc = ALUOUTE;
            end else if (regwriteM && Dra2 == dstM) begin
                if (memtoregM) sctlE.bc = MEMDATA;
                else sctlE.bc = ALUOUTM;
            end else sctlE.bc = RD;
        end
    end

endmodule

`endif