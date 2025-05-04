`timescale 1ns/1ps
`include "../define/axi_4_defs.svh"

import axi_4_pkg::*;

module axi_4_tb;

    // VLSU Simulation Signals
    logic clk, reset;
    logic ld_req, st_req;
    logic ld_req_reg, st_req_reg;
    logic [`XLEN-1:0] base_addr;
    logic [`DATA_BUS_WIDTH*BURST_MAX-1:0] vlsu_wdata;
    logic [STROBE_WIDTH*BURST_MAX-1:0] write_strobe;
    logic [7:0] burst_len;
    logic [2:0] burst_size;
    logic [1:0] burst_type;
    logic [`DATA_BUS_WIDTH*BURST_MAX-1:0] rdata;
    logic burst_valid_data, burst_wr_valid;

    // AXI Master <-> Slave interface
    logic s_arready, m_arvalid;
    logic s_rvalid, m_rready;
    logic s_awready, m_awvalid;
    logic s_wready, m_wvalid;
    logic s_bvalid, m_bready;

    // AXI Channels
    read_write_address_channel_t re_wr_addr_channel;
    write_data_channel_t         wr_data_channel;
    read_data_channel_t          re_data_channel;
    write_response_channel_t     wr_resp_channel;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Instantiate AXI Slave
    axi4_slave_mem u_axi_slave (
        .clk(clk), .reset(reset),
        .ld_req(ld_req_reg), .st_req(st_req_reg),
        .s_arready(s_arready), .m_arvalid(m_arvalid),
        .s_rvalid(s_rvalid), .m_rready(m_rready),
        .s_awready(s_awready), .m_awvalid(m_awvalid),
        .s_wready(s_wready), .m_wvalid(m_wvalid),
        .s_bvalid(s_bvalid), .m_bready(m_bready),
        .re_wr_addr_channel(re_wr_addr_channel),
        .wr_data_channel(wr_data_channel),
        .re_data_channel(re_data_channel),
        .wr_resp_channel(wr_resp_channel)
    );

    // Instantiate AXI Master
    axi_4_master u_axi_master (
        .clk(clk), .reset(reset),
        .ld_req(ld_req), .st_req(st_req),
        .s_arready(s_arready), .m_arvalid(m_arvalid),
        .s_rvalid(s_rvalid), .m_rready(m_rready),
        .s_awready(s_awready), .m_awvalid(m_awvalid),
        .s_wready(s_wready), .m_wvalid(m_wvalid),
        .s_bvalid(s_bvalid), .m_bready(m_bready),
        .base_addr(base_addr), .vlsu_wdata(vlsu_wdata),
        .write_strobe(write_strobe), .burst_len(burst_len),
        .burst_size(burst_size), .burst_type(burst_type),
        .burst_rdata_array(rdata),
        .burst_valid_data(burst_valid_data),
        .burst_wr_valid(burst_wr_valid),
        .ld_req_reg(ld_req_reg), .st_req_reg(st_req_reg),
        .re_wr_addr_channel(re_wr_addr_channel),
        .wr_data_channel(wr_data_channel),
        .re_data_channel(re_data_channel),
        .wr_resp_channel(wr_resp_channel)
    );

    // Test Sequence
    initial begin
        $display("Starting AXI4 TB simulation...");
        reset = 1;
        ld_req = 0;
        st_req = 0;
        vlsu_wdata = 0;
        base_addr = 32'h100;
        burst_len = 3;           // 4 beats
        burst_size = 3'd3;       // 8 bytes (2^6)
        burst_type = BURST_INCR;
        write_strobe = {STROBE_WIDTH*BURST_MAX{1'b1}};

        repeat(1) @(posedge clk);
        reset = 0;
        repeat(1) @(posedge clk);
        reset = 1;

        // Start Write Transaction
        vlsu_wdata = {
            64'hCAFEBABE00000001, 64'hCAFEBABE00000002,
            64'hCAFEBABE00000003, 64'hCAFEBABE00000004,
            64'hCAFEBABE00000005, 64'hCAFEBABE00000006,
            64'hCAFEBABE00000007, 64'hCAFEBABE00000008
        };
        st_req = 1;
        @(posedge clk);
        st_req = 0;

        // Wait some cycles before read
        repeat(30) @(posedge clk);

        // Start Read Transaction
        ld_req = 1;
        @(posedge clk);
        ld_req = 0;

        repeat(100) @(posedge clk);
        $display("Simulation finished.");
        $finish;
    end

endmodule
