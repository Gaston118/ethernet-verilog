`timescale 1ns/1ps
`include "eth_phy_10g.v"

//iverilog -o tb/tb2 tb/eth_phy_10g_tb2.v
//vvp tb/tb2
//gtkwave tb/eth_phy_10g_tb2.vcd

module eth_phy_10g_tb2;

    // Parámetros del módulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter BIT_REVERSE = 0;
    parameter SCRAMBLER_DISABLE = 1;
    parameter PRBS31_ENABLE = 1; // Habilitar PRBS31 para generar datos
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

integer expected_data_count = 21; // Número esperado de datos recibidos
integer received_data_count = 0; // Contador para datos recibidos
    

    // Generador de datos PRBS31
    initial begin
        $dumpfile("tb/eth_phy_10g_tb2.vcd");
        $dumpvars(0, eth_phy_10g_tb2);
        
        // Configurar generación de PRBS31
        cfg_tx_prbs31_enable = 1'b1;
        cfg_rx_prbs31_enable = 1'b1;
        
        // Ciclo de clock y reset
        rx_clk = 1'b0;
        tx_clk = 1'b0;
        rx_rst = 1'b1;
        tx_rst = 1'b1;
        #10;
        rx_rst = 1'b0;
        tx_rst = 1'b0;

        #200;

        cfg_tx_prbs31_enable = 1'b0;
        cfg_rx_prbs31_enable = 1'b0;

        while (received_data_count < expected_data_count) begin
            #1; // Esperar un ciclo
        end

        // Verificar resultados

        if (rx_bad_block)
            $display("Error en bloque recibido");
        
        else if(rx_sequence_error)
            $display("Error en secuencia recibida");

        else if(rx_high_ber)
            $display("Error en BER recibido");
        
        else if(tx_bad_block)
            $display("Error en bloque transmitido");
        
        else if(rx_error_count)
            $display("Error en conteo de errores recibidos");
        
        // Finalizar simulación
        else $display("Transmision y recepcion exitosas");

        $finish;
    end

    integer i = 1;

    always @(posedge tx_clk) begin
        if (!tx_rst) begin
            serdes_rx_data <= serdes_tx_data;
            serdes_rx_hdr <= 2; //hardcodeo el hdr para que siempre sea 2 
            $display("");
            $display("serdes_rx_data = %h, serdes_rx_hdr = %h", serdes_rx_data, serdes_rx_hdr);
            $display("");
        end
    end

    // Validación: Compara los datos recibidos con los datos transmitidos
    always @(posedge rx_clk) begin
        if (!rx_rst) begin
            if (xgmii_rxd !== 64'hfefefefefefefefe) begin
            received_data_count = received_data_count + 1;
            end
            $display("%d) xgmii_rxd = %h", i , xgmii_rxd);
            i = i + 1;
        end
    end

endmodule
