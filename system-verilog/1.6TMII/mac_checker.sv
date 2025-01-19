`timescale 1ns/100ps

module mac_checker #
(
    parameter int DATA_WIDTH        = 64,
    parameter int CTRL_WIDTH        = 8,
    parameter int FCS_WIDTH         = 32, 

    parameter [7:0] IDLE_CODE       = 8'h07,
    parameter [7:0] START_CODE      = 8'hFB,
    parameter [7:0] TERM_CODE       = 8'hFD, 
    parameter [7:0] PREAMBLE_CODE   = 8'h55,
    parameter [7:0] SFD_CODE        = 8'hD5,
    parameter [47:0] DST_ADDR_CODE  = 48'hFFFFFFFFFFFF,
    parameter [47:0] SRC_ADDR_CODE  = 48'h123456789ABC
)
(
    input logic                         clk,
    input logic                         i_rst_n,
    input logic [DATA_WIDTH-1:0]        i_rx_data [0:255],
    input logic [MAX_FRAME_SIZE-1:0]    i_rx_array_data,
    input logic [CTRL_WIDTH-1:0]        i_rx_ctrl,
    input logic [FCS_WIDTH-1:0]         i_rx_fcs,
    input logic                         i_data_valid,
    output logic                        preamble_error,
    output logic                        fcs_error,   
    output logic                        header_error,
    output logic                        payload_error
);

    // Parámetros de los tamaños de los campos en bytes 
    localparam int PREAMBLE_SIZE        = 6;    // PREAMBLE STATE
    localparam int SFD_SIZE             = 1;    // PREAMBLE STATE
    localparam int DA_SIZE              = 6;    // HEADER STATE
    localparam int SA_SIZE              = 6;    // HEADER STATE
    localparam int LENGTH_TYPE          = 2;    // HEADER STATE
    localparam int FCS_SIZE             = 4;    // FCS STATE
    localparam int MIN_MAC_CLIENT_DATA  = 46;   // PAYLOAD STATE
    localparam int MAX_MAC_CLIENT_DATA  = 1504; // PAYLOAD STATE

    localparam int MIN_FRAME_SIZE       = 64;
    localparam int MAX_FRAME_SIZE       = 1518;

    logic [15:0] length_type; // 2 bytes
    int payload_size;

    // Archivo de log
    integer log_file;
    integer counter; 
    reg [PREAMBLE_SIZE*8-1:0] preamble_accum;

    initial begin
        // Abrir archivo de log
        log_file = $fopen("F:/VERILOG-UNC/CODES/system-verilog/1.6TMII/tb/mac_checker.log", "w");
        if (log_file == 0) begin
            $display("Error: No se pudo abrir el archivo de log.");
            $finish;
        end
    end

    always_ff @(posedge i_data_valid or negedge i_rst_n) begin
        if (!i_rst_n) begin
            preamble_error <= 1'b0;
            header_error <= 1'b0;
            payload_error <= 1'b0;
            fcs_error <= 1'b0;
            counter <= 1;
        end else if (i_data_valid) begin
            // Inicialización de errores y acumuladores
            preamble_error <= 1'b0;
            header_error <= 1'b0;
            payload_error <= 1'b0;
            fcs_error <= 1'b0;
            preamble_accum = 48'b0;
    
            // Log del frame actual
            $fdisplay(log_file, "FRAME %d", counter);
            $fdisplay(log_file, "Verificación del preámbulo y SFD");
    
            // Verificar el preámbulo y SFD del frame en i_rx_array_data
            for (int i = 0; i < 8; i++) begin
                logic [7:0] current_byte;
                current_byte = i_rx_array_data[(i * 8) +: 8]; // Extraer byte actual
    
                if (i == 0 && current_byte == START_CODE) begin
                    $fdisplay(log_file, "START CODE: %h", current_byte);
                end else if (i > 0 && i < 7 && current_byte == PREAMBLE_CODE) begin
                    preamble_accum = {preamble_accum[PREAMBLE_SIZE*8-9:0], current_byte};
                end else if (i == 7 && current_byte == SFD_CODE) begin
                    $fdisplay(log_file, "PREAMBLE CODE: %h", preamble_accum);
                    $fdisplay(log_file, "SFD CODE: %h", current_byte);
                end else begin
                    preamble_error <= 1'b1;
                    $fdisplay(log_file, "ERROR: Byte inesperado %h", current_byte);
                end
            end
            counter = counter + 1;
        end
        $fflush(log_file);
    end    

    final begin
        // Cerrar el archivo al finalizar la simulación
        if (log_file != 0) begin
            $fclose(log_file);
        end
    end

endmodule


/*for (int i = 0; i < 8; i++) begin
                if (i == 0 && i_rx_data[0][i*8 +: 8] == START_CODE) begin
                    $fdisplay(log_file, "START CODE: %h", i_rx_data[0][i*8 +: 8]);
                end else if (i > 0 && i < 7 && i_rx_data[0][i*8 +: 8] == PREAMBLE_CODE) begin
                    preamble_accum = {preamble_accum[PREAMBLE_SIZE*8-1:0], i_rx_data[0][i*8 +: 8]};
                end else if (i == 7 && i_rx_data[0][i*8 +: 8] == SFD_CODE) begin
                    $fdisplay(log_file, "PREAMBLE CODE: %h", preamble_accum);
                    $fdisplay(log_file, "SFD CODE: %h", i_rx_data[0][i*8 +: 8]);
                end else begin
                    preamble_error <= 1'b1;
                    $fdisplay(log_file, "ERROR: %h", i_rx_data[0][i*8 +: 8]);
                end
            end*/
