`ifndef __DCACHE_SV
`define __DCACHE_SV

`ifdef VERILATOR
`include "include/common.sv"
/* You should not add any additional includes in this file */
`endif

module DCache 
	import common::*; #(
		/* You can modify this part to support more parameters */
		/* e.g. OFFSET_BITS, INDEX_BITS, TAG_BITS */
		parameter X = 1,
        localparam WORDS_PER_LINE = 16,
        localparam ASSOCIATIVITY = 2,
        localparam SET_NUM = 8,

        localparam OFFSET_BITS = $clog2(WORDS_PER_LINE),
        localparam INDEX_BITS = $clog2(SET_NUM),
        localparam POSITION_BITS = $clog2(ASSOCIATIVITY),
        localparam TAG_BITS = 64 - INDEX_BITS - OFFSET_BITS - 3, /* Maybe 32, or smaller */

        localparam type offset_t = logic [OFFSET_BITS-1:0],
        localparam type index_t = logic [INDEX_BITS-1:0],
        localparam type position_t = logic [POSITION_BITS-1:0],
        localparam type tag_t = logic [TAG_BITS-1:0],

        localparam type state_t = enum logic[2:0] {
            INIT, FETCH, WRITEBACK, SKIP, RESET
        }

	)(
	input logic clk, reset,

	input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);

`ifndef REFERENCE_CACHE

	/* TODO: Lab3 Cache */
    function offset_t get_offset(addr_t addr);
        return addr[3+OFFSET_BITS-1:3];
    endfunction

    function index_t get_index(addr_t addr);
        return addr[3+INDEX_BITS+OFFSET_BITS-1:OFFSET_BITS+3];
    endfunction

    function tag_t get_tag(addr_t addr);
        return addr[3+INDEX_BITS+OFFSET_BITS+TAG_BITS-1:3+INDEX_BITS+OFFSET_BITS];
    endfunction

    typedef struct packed {
        u1 valid;
        u1 dirty;
        tag_t tag;
    } meta_t;

    typedef struct packed {
        u1 en;
        strobe_t strobe;
        word_t wdata;
    } dram_t;

    typedef struct packed {
        u1 en;
        meta_t[ASSOCIATIVITY-1:0] wdata;
    } mram_t;

    state_t     state;
    offset_t    offset;
    offset_t    offset_cnt;
    index_t     index;
    index_t     reset_cnt;
    tag_t       tag;
    position_t  position;
    u1          hit;
    assign tag      = get_tag(dreq.addr);  

    position_t age[SET_NUM-1:0][ASSOCIATIVITY-1:0];
    dram_t dram;
    mram_t mram;
    word_t data;
    meta_t[ASSOCIATIVITY-1:0] meta;

    RAM_SinglePort #(
        .ADDR_WIDTH(OFFSET_BITS+INDEX_BITS+POSITION_BITS),
        .DATA_WIDTH(64),
        .BYTE_WIDTH(8),
        .READ_LATENCY(0)
    ) data_ram (
        .clk(clk), .en(dram.en),
        .addr({index,position,offset}),
        .strobe(dram.strobe),
        .wdata(dram.wdata),
        .rdata(data)
    );


    RAM_SinglePort #(
        .ADDR_WIDTH(INDEX_BITS),
        .DATA_WIDTH($bits(meta_t) * ASSOCIATIVITY),
        .BYTE_WIDTH($bits(meta_t) * ASSOCIATIVITY),
        .READ_LATENCY(0)
    ) meta_ram (
        .clk(clk), .en(mram.en),
        .addr(index),
        .strobe(mram.en),
        .wdata(mram.wdata),
        .rdata(meta)
    );
    

    always_comb begin
        position = '0;
        hit = '0;
        for(int i = 0; i <ASSOCIATIVITY; i++) begin
            if (meta[i].tag == tag && meta[i].valid == 1) begin
                position = i[POSITION_BITS-1:0];
                hit = 1;
                break;
            end
        end
        if(~hit) begin
            for(int i = 0; i <ASSOCIATIVITY; i++) begin
                if (meta[i].valid == 0 || age[index][i] == '1) begin
                    position = i[POSITION_BITS-1:0];
                    break;
                end
            end
        end
    end


    always_ff @(posedge clk) begin
        if (~reset) begin
            unique case (state)
                INIT: if (dreq.valid) begin
                    if(dreq.addr[31] == 0) state <= SKIP;
                    else if(~hit) state <= meta[position].dirty ? WRITEBACK : FETCH;
                    else begin
                        for(int i = 0; i <ASSOCIATIVITY; i++)
                            if (age[index][i] <= age[index][position])begin
                                age[index][i] <= age[index][i]+1;
                            end
                        age[index][position] <= '0;
                    end
                end

                FETCH: if (cresp.ready) begin
                    //$display("%x",creq.addr);
                    state  <= cresp.last ? INIT : FETCH;
                    offset_cnt <= offset_cnt + 1;
                end

                WRITEBACK: if (cresp.ready) begin
                    state  <= cresp.last ? FETCH : WRITEBACK;
                    offset_cnt <= offset_cnt + 1;
                end

                SKIP: state <= cresp.ready ? INIT : SKIP;

                RESET: begin
                    state <= INIT;
                    for(int i = 0; i <ASSOCIATIVITY; i++) age[index][i] <= '0;
                end

                default: state <= INIT;
            endcase
        end else begin
            state <= RESET;
            offset_cnt <= '0;
            reset_cnt <= reset_cnt+1;
        end
    end


    assign dresp.addr_ok = state == INIT;
    assign creq.valid    = state == FETCH || state == WRITEBACK || state == SKIP;


    always_comb begin
        index = get_index(dreq.addr);
        offset = get_offset(dreq.addr);
        dresp.data_ok = '0;
        dresp.data    = data;
        creq.is_write = '0;
        creq.size     = MSIZE8;
        creq.addr     = {meta[position].tag,get_index(dreq.addr),7'b0000000};
        creq.strobe   = 8'b11111111;
        creq.data     = data;
        creq.len      = MLEN16;
        creq.burst	  = AXI_BURST_INCR;
        dram = '0;
        mram = '0;
        unique case (state)
            INIT: begin
                if(dreq.valid) begin
                    offset = get_offset(dreq.addr);
                    if(hit) begin
                        dresp.data_ok = 1;
                        if(dreq.strobe !='0) begin
                            dram.en     = 1;
                            dram.strobe = dreq.strobe;
                            dram.wdata  = dreq.data;
                            mram.en     = 1;
                            mram.wdata  = meta;
                            mram.wdata[position].valid = 1;
                            mram.wdata[position].dirty = 1;
                            mram.wdata[position].tag   = meta[position].tag;
                        end
                    end
                end
            end

            FETCH: begin
                offset = offset_cnt;
                dram.en     = 1;
                dram.strobe = 8'b11111111;
                dram.wdata  = cresp.data;
                mram.en     = 1;
                mram.wdata  = meta;
                mram.wdata[position].valid = 1;
                mram.wdata[position].dirty = 0;
                mram.wdata[position].tag   = get_tag(dreq.addr);
                creq.addr = {get_tag(dreq.addr),get_index(dreq.addr),7'b0000000};
            end

            WRITEBACK: begin
                offset = offset_cnt;
                creq.is_write = '1;
            end

            SKIP: begin
                creq.addr = dreq.addr;
                creq.size = dreq.size;
                creq.strobe = dreq.strobe;
                creq.data = dreq.data;
                creq.len = MLEN1;
                creq.burst = AXI_BURST_FIXED;
                if(creq.strobe != 0) creq.is_write = 1;
                dresp.data = cresp.data;
                dresp.data_ok = cresp.ready;
            end

            RESET: begin
                index = reset_cnt;
                mram.en = 1;
                mram.wdata = '0;
            end

            default: begin
                dram = '0;
                mram = '0;
            end
        endcase
    end
    

`else

	typedef enum u2 {
		IDLE,
		FETCH,
		READY,
		FLUSH
	} state_t /* verilator public */;

	// typedefs
    typedef union packed {
        word_t data;
        u8 [7:0] lanes;
    } view_t;

    typedef u4 offset_t;

    // registers
    state_t    state /* verilator public_flat_rd */;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.
    offset_t   offset;

    // wires
    offset_t start;
    assign start = dreq.addr[6:3];

    // the RAM
    struct packed {
        logic    en;
        strobe_t strobe;
        word_t   wdata;
    } ram;
    word_t ram_rdata;

    always_comb
    unique case (state)
    FETCH: begin
        ram.en     = 1;
        ram.strobe = 8'b11111111;
        ram.wdata  = cresp.data;
    end

    READY: begin
        ram.en     = 1;
        ram.strobe = req.strobe;
        ram.wdata  = req.data;
    end

    default: ram = '0;
    endcase

    RAM_SinglePort #(
		.ADDR_WIDTH(4),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.READ_LATENCY(0)
	) ram_inst (
        .clk(clk), .en(ram.en),
        .addr(offset),
        .strobe(ram.strobe),
        .wdata(ram.wdata),
        .rdata(ram_rdata)
    );

    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata;

    // CBus driver
    assign creq.valid    = state == FETCH || state == FLUSH;
    assign creq.is_write = state == FLUSH;
    assign creq.size     = MSIZE8;
    assign creq.addr     = req.addr;
    assign creq.strobe   = 8'b11111111;
    assign creq.data     = ram_rdata;
    assign creq.len      = MLEN16;
	assign creq.burst	 = AXI_BURST_INCR;

    // the FSM
    always_ff @(posedge clk)
    if (~reset) begin
        unique case (state)
        IDLE: if (dreq.valid) begin
            state  <= FETCH;
            req    <= dreq;
            offset <= start;
        end

        FETCH: if (cresp.ready) begin
            state  <= cresp.last ? READY : FETCH;
            offset <= offset + 1;
        end

        READY: begin
            state  <= (|req.strobe) ? FLUSH : IDLE;
        end

        FLUSH: if (cresp.ready) begin
            state  <= cresp.last ? IDLE : FLUSH;
            offset <= offset + 1;
        end

        endcase
    end else begin
        state <= IDLE;
        {req, offset} <= '0;
    end

`endif

endmodule

`endif
