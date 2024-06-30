`timescale 1ns/1ps
`include "eth_phy_10g.v"

//-----------------------------------------------------
//iverilog -o tb/ll9 tb/eth_phy_10g_LL9.v
//vvp tb/ll9
//-----------------------------------------------------

module eth_phy_10g_LL9;

    // Parámetros del módulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter BIT_REVERSE = 0;
    parameter SCRAMBLER_DISABLE = 1;
    parameter PRBS31_ENABLE = 0; 
    parameter TX_SERDES_PIPELINE = 1;
    parameter RX_SERDES_PIPELINE = 1;
    parameter BITSLIP_HIGH_CYCLES = 1;
    parameter BITSLIP_LOW_CYCLES = 8;
    //parameter COUNT_125US = 125000/6.4;
    parameter COUNT_125US = 125;

    // Definición de señales
    reg rx_clk, rx_rst, tx_clk, tx_rst;
    reg [DATA_WIDTH-1:0] xgmii_txd;
    reg [CTRL_WIDTH-1:0] xgmii_txc;
    wire [DATA_WIDTH-1:0] xgmii_rxd;
    wire [CTRL_WIDTH-1:0] xgmii_rxc;
    wire [DATA_WIDTH-1:0] serdes_tx_data;
    wire [HDR_WIDTH-1:0]  serdes_tx_hdr;
    reg [DATA_WIDTH-1:0] serdes_rx_data;
    reg [HDR_WIDTH-1:0]  serdes_rx_hdr;
    wire serdes_rx_bitslip;
    wire serdes_rx_reset_req;
    wire tx_bad_block;
    wire [6:0] rx_error_count;
    wire rx_bad_block;
    wire rx_sequence_error;
    wire rx_block_lock;
    wire rx_high_ber;
    wire rx_status;
    reg cfg_tx_prbs31_enable, cfg_rx_prbs31_enable;

    // Instancia del DUT (Design Under Test)
    eth_phy_10g #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .BIT_REVERSE(BIT_REVERSE),
        .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
        .PRBS31_ENABLE(PRBS31_ENABLE),
        .TX_SERDES_PIPELINE(TX_SERDES_PIPELINE),
        .RX_SERDES_PIPELINE(RX_SERDES_PIPELINE),
        .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
        .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES),
        .COUNT_125US(COUNT_125US)
    ) dut (
        .rx_clk(rx_clk),
        .rx_rst(rx_rst),
        .tx_clk(tx_clk),
        .tx_rst(tx_rst),
        .xgmii_txd(xgmii_txd),
        .xgmii_txc(xgmii_txc),
        .xgmii_rxd(xgmii_rxd),
        .xgmii_rxc(xgmii_rxc),
        .serdes_tx_data(serdes_tx_data),
        .serdes_tx_hdr(serdes_tx_hdr),
        .serdes_rx_data(serdes_rx_data),
        .serdes_rx_hdr(serdes_rx_hdr),
        .serdes_rx_bitslip(serdes_rx_bitslip),
        .serdes_rx_reset_req(serdes_rx_reset_req),
        .tx_bad_block(tx_bad_block),
        .rx_error_count(rx_error_count),
        .rx_bad_block(rx_bad_block),
        .rx_sequence_error(rx_sequence_error),
        .rx_block_lock(rx_block_lock),
        .rx_high_ber(rx_high_ber),
        .rx_status(rx_status),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable),
        .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable)
    );

    always #5 rx_clk = ~rx_clk;
    always #5 tx_clk = ~tx_clk;

    reg [63:0] test_patterns [0:5];
    initial begin
    test_patterns[0] = 64'hFFFFFFFFFFFFFFFF; 
    test_patterns[1] = 64'h0000000000000000; 
    test_patterns[2] = 64'h5555555555555555; 
    test_patterns[3] = 64'hAAAAAAAAAAAAAAAA; 
    test_patterns[4] = 64'hFEFEFEFEFEFEFEFE; 
    test_patterns[5] = 64'h0707070707070707; 
    end
    
    integer i;
    reg [15:0] random_number;
    integer valid=0;
    integer invalid=0;

    always @(posedge tx_clk) begin
        if (!tx_rst) begin
            for (i=0; i<6; i=i+1) begin
                xgmii_txd <= test_patterns[i];
                #10;
                serdes_rx_data <= serdes_tx_data;
                //serdes_rx_hdr = 2'b01; //CON 1 SE ACTIVA EL RX STATUS
                //serdes_rx_hdr = 2'b10; //LOS DATOS SOLO LLEGAN BIEN SI ES 2

                random_number = $urandom%100;

                $display("Numero: %0d", random_number);

                if(random_number<=2) begin
                    serdes_rx_hdr = 2'b11;
                    invalid = invalid + 1;
                end
                else begin
                    serdes_rx_hdr = 2'b01;
                    valid = valid + 1;
                end

                $display("----------------------------------------------------------------------");
                $display("serdes_tx_data = %h, serdes_tx_hdr = %h", serdes_tx_data, serdes_tx_hdr);
                $display("");
                $display("serdes_rx_data = %h, serdes_rx_hdr = %h", serdes_rx_data, serdes_rx_hdr);
                $display("----------------------------------------------------------------------");
            end
        end
    end

    always @(posedge rx_clk) begin
        if (!rx_rst) begin 
            $display("");
            $display("xgmii_rxd = %h", xgmii_rxd);
            $display("");
        end
    end
    
    always @(posedge rx_clk) begin
        if (!rx_rst) begin 
            $display("");
            $display("Time: %t ", $time);
            $display("rx_block_lock: %b | rx_high_ber: %b | rx_status: %b | rx_error_count: %d", rx_block_lock, rx_high_ber, rx_status, rx_error_count);
            $display("ber_count: %d", dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_ber_mon_inst.ber_count_reg);
            $display("status_count: %h", dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_watchdog_inst.status_count_reg);
            $display("error_count_reg: %b", dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_watchdog_inst.error_count_reg);
            $display("");
            if(rx_status) begin
                $display("rx_status: OK");
                $display("Valid: %0d", valid);
                $display("Invalid: %0d", invalid);
                $display("TOTAL: %0d", valid + invalid);
                $finish;
            end
        end
    end

    initial begin
        $dumpfile("tb/eth_phy_10g_ll9.vcd");
        $dumpvars(0, eth_phy_10g_LL9);

        cfg_rx_prbs31_enable <= 1'b0;
        cfg_tx_prbs31_enable <= 1'b0;

        rx_clk = 1'b0;
        tx_clk = 1'b0;
        rx_rst = 1'b1;
        tx_rst = 1'b1;
        #10;
        rx_rst = 1'b0;
        tx_rst = 1'b0;

        xgmii_txd = {test_patterns[1]};
        xgmii_txc = 8'h00;

        #100;
        
        rx_rst = 1'b1;
        tx_rst = 1'b1;
        #10;
        rx_rst = 1'b0;
        tx_rst = 1'b0;

        #55800;

        $display("Valid: %0d", valid);
        $display("Invalid: %0d", invalid);
        $display("TOTAL: %0d", valid + invalid);

        $finish;
    end

endmodule