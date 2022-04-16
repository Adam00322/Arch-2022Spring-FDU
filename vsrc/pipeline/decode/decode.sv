`ifndef  __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`endif

module decode
    import pipes::*;
    import common::*;(
    
    input fetch_data_t dataF,
    output decode_data_t dataD,
    output addr_t PCbranch,
    output u1 branch,
    output decode_op_t op,
    
    input word_t rd1,rd2,
    output creg_addr_t ra1,ra2,

    input word_t aluoutE,
    input word_t aluoutM,
    input word_t memdata,
    input supercontrol_t sctlD
);
    u32  raw_instr;
    u64 imm;
    word_t t;
    im_t im;

    assign raw_instr = dataF.raw_instr;

    assign dataD.valid = dataF.valid;
    // assign dataD.srca = rd1;
    // assign dataD.srcb = rd2;
    assign ra1 = raw_instr[19:15];
    assign ra2 = raw_instr[24:20];
    assign dataD.dst = raw_instr[11:7];
    assign dataD.pc = dataF.pc;
    assign dataD.raw_instr = dataF.raw_instr;
    assign dataD.imm = imm;
    assign dataD.ra1 = ra1;
    assign dataD.ra2 = ra2;

    
    always_comb begin
        unique case (im)
            I_ADDI: imm = {{52{raw_instr[31]}},raw_instr[31:20]};
            I_SD: imm = {{52{raw_instr[31]}},raw_instr[31:25], raw_instr[11:7]};
            I_LUI: imm = {{32{raw_instr[31]}}, raw_instr[31:12],  {12{1'b0}}};
            I_JAL: imm = dataF.pc+4;
            I_BEQ: imm = {{52{raw_instr[31]}}, raw_instr[7], raw_instr[30:25], raw_instr[11:8], 1'b0};
            I_AUIPC: imm = {{32{raw_instr[31]}}, raw_instr[31:12], 12'b000000000000} + dataF.pc;
            default: imm = 0;
        endcase
    end

    always_comb begin
        unique case (sctlD.ac)
            RD: dataD.srca = rd1;
            ALUOUTE: dataD.srca = aluoutE;
            ALUOUTM: dataD.srca = aluoutM;
            MEMDATA: dataD.srca = memdata;
            default: dataD.srca = rd1;
        endcase
    end

    always_comb begin
        unique case (sctlD.bc)
            RD: dataD.srcb = rd2;
            ALUOUTE: dataD.srcb = aluoutE;
            ALUOUTM: dataD.srcb = aluoutM;
            MEMDATA: dataD.srcb = memdata;
            default: dataD.srcb = rd2;
        endcase
    end

    always_comb begin
        if(op == OP_BEQ)begin
            if(dataD.srca==dataD.srcb)begin
                branch = 1;
                PCbranch = dataF.pc+imm;
            end else branch = 0;
        end else if (op == OP_JAL) begin
            PCbranch = dataF.pc+{{44{raw_instr[31]}}, raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};
            branch = 1;
        end else if (op == OP_JALR) begin
            PCbranch = (dataD.srca + {{52{raw_instr[31]}},raw_instr[31:20]})&~1;
            branch = 1;
        end else branch = 0;
    end

    decoder decoder(
        .f7(raw_instr[6:0]),
        .f7_2(raw_instr[31:25]),
        .f3(raw_instr[14:12]),
        .ctl(dataD.ctl),
        .op,
        .im(im)
    );
    
    
endmodule


`endif