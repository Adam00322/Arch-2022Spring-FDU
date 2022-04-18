`ifndef  __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module decoder
    import pipes::*;
    import common::*;(
    
    input wire [6:0] f7,
    input wire [6:0] f7_2,
    input wire [2:0] f3,
    input wire [5:0] f6,
    output control_t ctl,
    output decode_op_t op,
    output im_t im
);

    always_comb begin
        unique case (f7)
            F7_ADDI:begin
                unique case (f3)
                    F3_ADDI:begin
                        op = OP_ADDI;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_XORI:begin
                        op = OP_XORI;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_XOR;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_ORI:begin
                        op = OP_ORI;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_OR;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_ANDI:begin
                        op = OP_ANDI;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_AND;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_SLTI:begin
                        op = OP_SLTI;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_SLT;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_SLTIU:begin
                        op = OP_SLTIU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_SLTU;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_SLLI:begin
                        unique case (f6)
                            F6_SLLI: begin
                                op = OP_SLLI;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SLL;
                                ctl.alusrc = 1;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_SLLI;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SRLI:begin
                        unique case (f6)
                            F6_SRLI: begin
                                op = OP_SRLI;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRL;
                                ctl.alusrc = 1;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_SLLI;
                            end
                            F6_SRAI: begin
                                op = OP_SRAI;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRA;
                                ctl.alusrc = 1;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_SLLI;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    default: ctl = '0;
                endcase
            end
            F7_ADDIW:begin
                unique case (f3)
                    F3_ADDI:begin
                        op = OP_ADDIW;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADDW;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 1;
                        ctl.memtoreg = 0;
                        im = I_ADDI;
                    end
                    F3_SLLI:begin
                        unique case (f6)
                            F6_SLLI: begin
                                op = OP_SLLIW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SLLW;
                                ctl.alusrc = 1;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_SLLI;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SRLI:begin
                        unique case (f6)
                            F6_SRLI: begin
                                op = OP_SRLIW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRLW;
                                ctl.alusrc = 1;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_SLLI;
                            end
                            F6_SRAI: begin
                                op = OP_SRAIW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRAW;
                                ctl.alusrc = 1;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_SLLI;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    default: ctl = '0;
                endcase
            end
            F7_LUI:begin
                op = OP_LUI;
                ctl.regwrite = 1;
                ctl.alufunc = NULL;
                ctl.alusrc = 1;
                ctl.memread = 0;
                ctl.memwrite = 0;
                ctl.memtoreg = 0;
                im = I_LUI;
            end
            F7_JAL:begin
                op = OP_JAL;
                ctl.regwrite = 1;
                ctl.alufunc = NULL;
                ctl.alusrc = 1;
                ctl.memread = 0;
                ctl.memwrite = 0;
                ctl.memtoreg = 0;
                im = I_JAL;
            end
            F7_BEQ:begin
                unique case (f3)
                    F3_BEQ:begin
                        op = OP_BEQ;
                        ctl.regwrite = 0;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 0;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_BEQ;
                    end
                    F3_BNE:begin
                        op = OP_BNE;
                        ctl.regwrite = 0;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 0;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_BEQ;
                    end
                    F3_BLT:begin
                        op = OP_BLT;
                        ctl.regwrite = 0;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 0;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_BEQ;
                    end
                    F3_BLTU:begin
                        op = OP_BLTU;
                        ctl.regwrite = 0;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 0;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_BEQ;
                    end
                    F3_BGE:begin
                        op = OP_BGE;
                        ctl.regwrite = 0;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 0;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_BEQ;
                    end
                    F3_BGEU:begin
                        op = OP_BGEU;
                        ctl.regwrite = 0;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 0;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_BEQ;
                    end
                    default: ctl = '0;
                endcase
            end
            F7_LD:begin
                unique case (f3)
                    F3_LD:begin
                        op = OP_LD;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                        ctl.alusrc = 1;
                        ctl.memread = 1;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 1;
                        im = I_ADDI;
                    end
                    default: ctl = '0;
                endcase
            end
            F7_SD:begin
                unique case (f3)
                    F3_SD:begin
                        op = OP_SD;
                        ctl.regwrite = 0;
                        ctl.alufunc = ALU_ADD;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 1;
                        ctl.memtoreg = 0;
                        im = I_SD;
                    end
                    default: ctl = '0;
                endcase
            end
            F7_ADD:begin
                unique case (f3)
                    F3_ADD:begin
                        unique case (f7_2)
                            F7_ADD_2:begin
                                op = OP_ADD;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_ADD;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            F7_SUB_2:begin
                                op = OP_SUB;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SUB;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_AND:begin
                        unique case (f7_2)
                            F7_AND_2:begin
                                op = OP_AND;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_AND;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_OR:begin
                        unique case (f7_2)
                            F7_OR_2:begin
                                op = OP_OR;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_OR;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_XOR:begin
                        unique case (f7_2)
                            F7_XOR_2:begin
                                op = OP_XOR;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_XOR;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SLL:begin
                        unique case (f7_2)
                            F7_SLL_2:begin
                                op = OP_SLL;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SLL;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SLT:begin
                        unique case (f7_2)
                            F7_SLT_2:begin
                                op = OP_SLT;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SLT;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SLTU:begin
                        unique case (f7_2)
                            F7_SLTU_2:begin
                                op = OP_SLTU;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SLTU;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SRL:begin
                        unique case (f7_2)
                            F7_SRL_2:begin
                                op = OP_SRL;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRL;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            F7_SRA_2:begin
                                op = OP_SRA;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRA;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    default: ctl = '0;
                endcase
            end
            F7_ADDW:begin
                unique case (f3)
                    F3_ADD:begin
                        unique case (f7_2)
                            F7_ADD_2:begin
                                op = OP_ADDW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_ADDW;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            F7_SUB_2:begin
                                op = OP_SUBW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SUBW;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SLL:begin
                        unique case (f7_2)
                            F7_SLL_2:begin
                                op = OP_SLLW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SLLW;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    F3_SRL:begin
                        unique case (f7_2)
                            F7_SRL_2:begin
                                op = OP_SRLW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRLW;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            F7_SRA_2:begin
                                op = OP_SRAW;
                                ctl.regwrite = 1;
                                ctl.alufunc = ALU_SRAW;
                                ctl.alusrc = 0;
                                ctl.memread = 0;
                                ctl.memwrite = 0;
                                ctl.memtoreg = 0;
                                im = I_NULL;
                            end
                            default: ctl = '0;
                        endcase
                    end
                    default: ctl = '0;
                endcase
            end
            F7_AUIPC:begin
                op = OP_AUIPC;
                ctl.regwrite = 1;
                ctl.alufunc = NULL;
                ctl.alusrc = 1;
                ctl.memread = 0;
                ctl.memwrite = 0;
                ctl.memtoreg = 0;
                im = I_AUIPC;
            end
            F7_JALR:begin
                unique case (f3)
                    F3_JALR:begin
                        op = OP_JALR;
                        ctl.regwrite = 1;
                        ctl.alufunc = NULL;
                        ctl.alusrc = 1;
                        ctl.memread = 0;
                        ctl.memwrite = 0;
                        ctl.memtoreg = 0;
                        im = I_JAL;
                    end
                    default: ctl = '0;
                endcase
            end
            default: begin
                ctl = '0;
                im = I_NULL;
                op = UNKNOWN;
            end
        endcase
        
    end
    
    
endmodule


`endif