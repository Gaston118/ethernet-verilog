`timescale 1ns/1ns
`include "eth_phy_10g.v"

module eth_phy_10g_tb2;

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

    // Generación de clocks
    always begin
        #3 rx_clk <= ~rx_clk; 
    end

    always begin
       #3 tx_clk <= ~tx_clk; 
    end

    // Generador PRBS31
    reg [30:0] prbs31_tx;
    reg [30:0] prbs31_rx;

    always @(posedge tx_clk) begin //se ejecutará en cada flanco de subida del reloj tx_clk.
        if (cfg_tx_prbs31_enable) //verifica si la señal de control cfg_tx_prbs31_enable está activada. Si es así, se procede a generar la secuencia PRBS31 para la transmisión.
            prbs31_tx <= {prbs31_tx[29:0], prbs31_tx[27:0] ^ prbs31_tx[28] ^ prbs31_tx[29]};
    end

    always @(posedge rx_clk) begin //se ejecutará en cada flanco de subida del reloj rx_clk.
        if (cfg_rx_prbs31_enable) //verifica si la señal de control cfg_rx_prbs31_enable está activada. Si es así, se procede a generar la secuencia PRBS31 para la transmisión.
            prbs31_rx <= {prbs31_rx[29:0], prbs31_rx[27:0] ^ prbs31_rx[28] ^ prbs31_rx[29]};
    end

    /*
    {prbs31_tx[29:0], prbs31_tx[27:0] ^ prbs31_tx[28] ^ prbs31_tx[29]}
    es una concatenación de bits que forma la nueva secuencia PRBS31. 
    Se toma la secuencia PRBS31 actual (prbs31_tx[29:0]) y se le agrega un nuevo bit 
    generado por una operación XOR (bit a bit) de tres bits específicos de la secuencia 
    actual (prbs31_tx[27:0] ^ prbs31_tx[28] ^ prbs31_tx[29]).
    La expresión prbs31_tx[27:0] ^ prbs31_tx[28] ^ prbs31_tx[29] representa 
    un generador de secuencia PRBS de 3-bits, donde los bits en las posiciones 
    27, 28 y 29 de la secuencia actual se combinan utilizando XOR. 
    El resultado de esta operación XOR se convierte en el nuevo bit que se agrega 
    a la secuencia PRBS31.
    Todos los bits, excepto el bit en la posición 0, se desplazan hacia la izquierda 
    en cada ciclo de reloj, mientras que el bit en la posición 0 se calcula mediante 
    una operación XOR de ciertos bits específicos del registro en cada ciclo de reloj.
    */

    // Asignaciones de datos
    always @(posedge tx_clk) begin
    if (cfg_tx_prbs31_enable)
        xgmii_txd <= prbs31_tx;
    else
        xgmii_txd <= 64'h0; // Enviar datos cero si PRBS31 está deshabilitado
    end

    always @(posedge rx_clk) begin
    if (cfg_rx_prbs31_enable)
        serdes_rx_data <= prbs31_rx;
    else
        serdes_rx_data <= 64'h0; // Recibir datos cero si PRBS31 está deshabilitado
    end

    always @(posedge rx_clk) begin
        serdes_rx_hdr <= 2'b00; // Header arbitrario
    end

    /*  xgmii_txd: representa los datos que se transmiten desde la interfaz XGMII 
    hacia el módulo (eth_phy_10g). 
    Cuando cfg_tx_prbs31_enable está habilitado, los datos generados por el PRBS31 
    se cargan en xgmii_txd, lo que simula la transmisión de datos a través de 
    la interfaz XGMII hacia el DUT.
    serdes_rx_data: representa los datos que se reciben en el módulo 
    (eth_phy_10g) a través del bloque de recepción SerDes. 
    La secuencia PRBS31 generada (prbs31_rx) se asigna a serdes_rx_data cuando 
    cfg_rx_prbs31_enable está habilitado.
    */

    // Asignación de instanciación del módulo
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

    // Inicialización de la simulación y verificación de resultados
    initial begin
        $dumpfile("eth_phy_10g_tb2.vcd"); 
        $dumpvars(0, eth_phy_10g_tb2); // Dump de todas las variables

        // Reset inicial
        tx_rst <= 1'b0;
        rx_rst <= 1'b0;
        #10;
        tx_rst <= 1'b1;
        rx_rst <= 1'b1;
        #10;
        tx_rst <= 1'b0;
        rx_rst <= 1'b0;
        #10;

        //cfg_tx_prbs31_enable = 1'b0; // Deshabilitar PRBS31 para transmisión
        //cfg_rx_prbs31_enable = 1'b0; // Deshabilitar PRBS31 para recepción

        cfg_tx_prbs31_enable = 1'b1; // Habilitar PRBS31 para transmisión
        cfg_rx_prbs31_enable = 1'b1; // Habilitar PRBS31 para recepción

        // Esperar un poco antes de verificar los resultados
        #1000;

        // Verificar resultados
        if(!cfg_tx_prbs31_enable || !cfg_rx_prbs31_enable)
            $display("PRBS31 deshabilitado");

        if (rx_bad_block || rx_sequence_error || rx_high_ber || tx_bad_block || rx_block_lock || rx_error_count)
            $display("Error de transmision o recepcion detectado.");
        else
            $display("Transmision y recepcion exitosas.");

        // Finalizar la simulación
        $finish;
    end

    always @(posedge rx_clk) begin
        if (!rx_rst) begin
            // Compara solo si no está en estado de reinicio
            if (xgmii_rxd !== xgmii_txd) begin
                $display("Error: Datos recibidos no coinciden con los datos transmitidos");
            end
        end
    end

endmodule
