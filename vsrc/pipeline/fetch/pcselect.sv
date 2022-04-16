`ifndef  __PCSELECT_SV
`define __PCSELECT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module pcselect
    import pipes::*;
    import common::*;(
    
    input u64 pcplus4,
    input logic branch,
    input u64 PCbranch,
    output pc_selected
);
    
    always_comb begin
       if(branch)begin
           pc_selected = PCbranch;
       end else begin
           pc_selected = pcplus4;
       end
    end
    
endmodule


`endif