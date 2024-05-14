`timescale 1ns/1ns
`include "eth_phy_10g.v"

module eth_phy_10g_tb;

    // Parámetros del módulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter BIT_REVERSE = 0;
    parameter SCRAMBLER_DISABLE = 1;
    parameter PRBS31_ENABLE = 0;
    parameter TX_SERDES_PIPELINE = 0;
    parameter RX_SERDES_PIPELINE = 0;
    parameter BITSLIP_HIGH_CYCLES = 1;
    parameter BITSLIP_LOW_CYCLES = 8;
    parameter COUNT_125US = 125000/6.4;

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

    always
    // CAMBIOS
    // Cambio de begin a fork para que sea paralelo y no secuencial
    fork
        #5 rx_clk = ~rx_clk;
        #5 tx_clk = ~tx_clk;
    join

    integer i;

    // Generación de clocks
    initial begin

        $dumpfile("eth_phy_10g_tb.vcd");
        $dumpvars(0, eth_phy_10g_tb);

        cfg_rx_prbs31_enable = 1'b0;
        cfg_tx_prbs31_enable = 1'b0;

        rx_clk = 1'b0;
        tx_clk = 1'b0;
        rx_rst = 1'b1;
        tx_rst = 1'b1;
        #10;
        rx_rst = 1'b0;
        tx_rst = 1'b0;

        #50;

        // Verificar resultados
        if (rx_bad_block || rx_sequence_error || rx_high_ber || tx_bad_block || rx_block_lock || rx_error_count != 0) begin
            $display("Error de transmision o recepcion detectado.");
            $display("xgmii_rxd = %h", xgmii_rxd);
        end else begin
            $display("Transmision y recepcion exitosas.");
            $display("xgmii_rxd = %h", xgmii_rxd);
        end

        // Terminar la simulación
        $finish;
    end

    always @(posedge tx_clk) begin
        if (!tx_rst) begin 
            xgmii_txd <= 64'hA5A5_A5A5_A5A5_A5A5;
            serdes_rx_data <= serdes_tx_data;
            serdes_rx_hdr <= 2; //hardcodeo el hdr para que siempre sea 2 
            $display("");
            $display("serdes_rx_data = %h, serdes_rx_hdr = %h serdes_tx_hdr = %h", serdes_rx_data, serdes_rx_hdr, serdes_tx_hdr);
            $display("");
        end
    end

    always @(posedge rx_clk) begin
        if (!rx_rst) begin
            $display("xgmii_rxd = %h", xgmii_rxd);
        end
    end

endmodule
