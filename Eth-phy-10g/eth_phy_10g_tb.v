`timescale 1ns/1ns
`include "eth_phy_10g.v"

module eth_phy_10g_tb;

    // Parámetros del módulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;

    // Señales de clock y reset
    reg rx_clk;
    reg tx_clk;
    reg rx_rst;
    reg tx_rst;

    // Señales de datos XGMII
    reg [DATA_WIDTH-1:0] xgmii_txd;
    reg [CTRL_WIDTH-1:0] xgmii_txc;
    wire [DATA_WIDTH-1:0] xgmii_rxd;
    wire [CTRL_WIDTH-1:0] xgmii_rxc;

    // Señales de datos SerDes
    wire [DATA_WIDTH-1:0] serdes_tx_data;
    wire [HDR_WIDTH-1:0]  serdes_tx_hdr;
    reg [DATA_WIDTH-1:0] serdes_rx_data;
    reg [HDR_WIDTH-1:0]  serdes_rx_hdr;
    wire serdes_rx_bitslip;
    wire serdes_rx_reset_req;

    // Señales de estado
    wire tx_bad_block;
    wire [6:0] rx_error_count;
    wire rx_bad_block;
    wire rx_sequence_error;
    wire rx_block_lock;
    wire rx_high_ber;
    wire rx_status;

    // Señales de configuración
    reg cfg_tx_prbs31_enable;
    reg cfg_rx_prbs31_enable;

    // Salida para el archivo VCD
    initial begin
        $dumpfile("eth_phy_10g_tb.vcd"); // Nombre del archivo VCD
        $dumpvars(0, eth_phy_10g_tb); // Dump de todas las variables
    end

    eth_phy_10g #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH)
    ) dut (
        .rx_clk(rx_clk),
        .tx_clk(tx_clk),
        .rx_rst(rx_rst),
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

    // Generación de clocks

    // Genera la señal de reloj
    //El operador #3 indica un retraso de 3 unidades de tiempo de simulación. 
    //Después de cada retraso, el valor se invierte, alternando entre alto y bajo. 
    //Esto simula el comportamiento de una señal de reloj.

    always begin
        #3 rx_clk <= ~rx_clk; 
    end

    always begin
       #3 tx_clk <= ~tx_clk; 
    end

    initial begin
    tx_rst <= 1'b0; //ESTABLECE EL RESET DE TX EN 0
    rx_rst <= 1'b0; //ESTABLECE EL RESET DE RX EN 0
    #10;
    tx_rst <= 1'b1; //ESTABLECE EL RESET DE TX EN 1
    rx_rst <= 1'b1; //ESTABLECE EL RESET DE RX EN 1
    #10;
    tx_rst <= 1'b0; //ESTABLECE EL RESET DE TX EN 0
    rx_rst <= 1'b0; //ESTABLECE EL RESET DE RX EN 0
    #10;

    // Envío de datos de prueba
    xgmii_txd = 64'hA5A5_A5A5_A5A5_A5A5; // Patrón de datos de prueba
    xgmii_txc = 8'hFF; // Control de transmisión arbitrario
    serdes_rx_hdr = 2'h0; // Header arbitrario
    #10;
    // Verificar resultados
    if (rx_bad_block || rx_sequence_error || rx_high_ber || tx_bad_block || rx_block_lock || rx_error_count) begin
        $display("Error de transmision o recepcion detectado.");
    end else begin
        $display("Transmision y recepcion exitosas.");
    end

    xgmii_txd <= 64'hDEADBEEFDEADBEEF; // Cambiar el patrón de datos
    xgmii_txc <= 1'b1; // Set the TX control signal
    #10;
    xgmii_txc <= 1'b0; // Clear the TX control signal
    #10;
    // Verificar resultados
    if (rx_bad_block || rx_sequence_error || rx_high_ber || tx_bad_block || rx_block_lock || rx_error_count) begin
        $display("Error de transmision o recepcion detectado en 2do envio.");
    end else begin
        $display("Transmision y recepcion exitosas en 2do envio.");
    end
    
    // Terminar la simulación
    $finish;
    end

endmodule
