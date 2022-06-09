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

    input word_t rd,
    output csr_addr_t ra,
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
    assign ra = raw_instr[31:20];
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
            I_SLLI: imm = {58'b0, raw_instr[25:20]};
            I_CSR: imm = rd;
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
        PCbranch = '0;
        unique case (op)
            OP_BEQ:begin
                if(dataD.srca==dataD.srcb)begin
                    branch = 1;
                    PCbranch = dataF.pc+imm;
                end else branch = 0;
            end
            OP_BNE:begin
                if(dataD.srca!=dataD.srcb)begin
                    branch = 1;
                    PCbranch = dataF.pc+imm;
                end else branch = 0;
            end
            OP_BLT:begin
                if($signed(dataD.srca)<$signed(dataD.srcb))begin
                    branch = 1;
                    PCbranch = dataF.pc+imm;
                end else branch = 0;
            end
            OP_BLTU:begin
                if(dataD.srca<dataD.srcb)begin
                    branch = 1;
                    PCbranch = dataF.pc+imm;
                end else branch = 0;
            end
            OP_BGE:begin
                if($signed(dataD.srca)>=$signed(dataD.srcb))begin
                    branch = 1;
                    PCbranch = dataF.pc+imm;
                end else branch = 0;
            end
            OP_BGEU:begin
                if(dataD.srca>=dataD.srcb)begin
                    branch = 1;
                    PCbranch = dataF.pc+imm;
                end else branch = 0;
            end
            OP_JAL:begin
                PCbranch = dataF.pc+{{44{raw_instr[31]}}, raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};
                branch = 1;
            end
            OP_JALR:begin
                PCbranch = (dataD.srca + {{52{raw_instr[31]}},raw_instr[31:20]})&~1;
                branch = 1;
            end
            default: branch = 0;
        endcase
    end

    always_comb begin
        dataD.csr = '0;
        unique case (op)
            UNKNOWN: begin
                
            end
            OP_CSRRW: begin
                dataD.csr.wvalid = 1;
                dataD.csr.wa = ra;
                dataD.csr.wd = dataD.srca;
            end
            OP_CSRRS: begin
                dataD.csr.wvalid = 1;
                dataD.csr.wa = ra;
                dataD.csr.wd = rd | dataD.srca;
            end
            OP_CSRRC: begin
                dataD.csr.wvalid = 1;
                dataD.csr.wa = ra;
                dataD.csr.wd = rd & ~dataD.srca;
            end
            OP_CSRRWI: begin
                dataD.csr.wvalid = 1;
                dataD.csr.wa = ra;
                dataD.csr.wd = {59'b0,raw_instr[19:15]};
            end
            OP_CSRRSI: begin
                dataD.csr.wvalid = 1;
                dataD.csr.wa = ra;
                dataD.csr.wd = rd | {59'b0,raw_instr[19:15]};
            end
            OP_CSRRCI: begin
                dataD.csr.wvalid = 1;
                dataD.csr.wa = ra;
                dataD.csr.wd = rd & ~{59'b0,raw_instr[19:15]};
            end
            OP_MRET: begin
                dataD.csr.is_mret = 1;
            end
            default: dataD.csr = '0;
        endcase
    end

    decoder decoder(
        .f7(raw_instr[6:0]),
        .f7_2(raw_instr[31:25]),
        .f3(raw_instr[14:12]),
        .f6(raw_instr[31:26]),
        .ctl(dataD.ctl),
        .op,
        .im(im)
    );
    
    
endmodule


`endif