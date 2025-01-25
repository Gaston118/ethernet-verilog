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
    logic [47:0] sa; // 6 bytes
    logic [47:0] da; // 6 bytes
    logic [FCS_WIDTH-1:0] fcs; // 4 bytes
    integer payload_size; // Tamaño del payload
    integer payload_counter; // Contador de bytes del payload
    logic [31:0] calculated_fcs;

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
            preamble_error <= 'd0;
            header_error <= 'd0;
            payload_error <= 'd0;
            fcs_error <= 'd0;
            counter <= 1;
            payload_size <= 0;
            payload_counter <= 0;
        end else if (i_data_valid) begin
            // Inicialización de errores y acumuladores
            preamble_error <= 'd0;
            header_error <= 'd0;
            payload_error <= 'd0;
            fcs_error <= 'd0;
            preamble_accum <= 48'b0;
            payload_counter <= 0;
            payload_size <= 0;

            $fdisplay(log_file, "\n=========================================\n");

            // Log del frame actual
            $fdisplay(log_file, "FRAME %d", counter);
            $fdisplay(log_file, "----> PREAMBULO y SFD <----");
    
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
                    preamble_error <= 'd1;
                    $fdisplay(log_file, "ERROR: Byte inesperado %h", current_byte);
                end
            end

            // Verificar el header del frame 
            // SA - DA - LENGTH_TYPE
            $fdisplay(log_file, "----> HEADER (SA, DA, LENGTH_TYPE) <----");

            da = i_rx_array_data[64 +: 48];
            if (da == DST_ADDR_CODE) begin
                $fdisplay(log_file, "DA: %h", da);
            end else begin
                header_error <= 'd1;
                $fdisplay(log_file, "ERROR: DA inesperado %h", da);
            end

            sa = i_rx_array_data[112 +: 48];
            if (sa == SRC_ADDR_CODE) begin
                $fdisplay(log_file, "SA: %h", sa);
            end else begin
                header_error <= 'd1;
                $fdisplay(log_file, "ERROR: SA inesperado %h", sa);
            end

            length_type = i_rx_array_data[160 +: 16];
            $fdisplay(log_file, "LENGTH_TYPE: %h", length_type);

            // Verificar el payload del frame
            $fdisplay(log_file, "----> PAYLOAD <----");
            payload_size = length_type;
            $fdisplay(log_file, "PAYLOAD SIZE: %d", payload_size);

            if (payload_size < MIN_MAC_CLIENT_DATA || payload_size > MAX_MAC_CLIENT_DATA) begin
                payload_error <= 'd1;
                $fdisplay(log_file, "ERROR: PAYLOAD SIZE %d", payload_size);
            end else begin
                // Contar Bytes de payload 
                for(int k = 176; k < payload_size + 176 + 40; k = k+8) begin
                    logic [7:0] current_byte;
                    current_byte = i_rx_array_data[k +: 8]; 

                    if(current_byte != TERM_CODE) begin
                        payload_counter = payload_counter + 1;
                    end else begin
                        $fdisplay(log_file, "TERMINATION CODE %h", current_byte);
                        payload_counter = payload_counter - 5; 
                        // 1 byte term code y 4 de FCS
                        fcs = i_rx_array_data[(k - 32) +: 32];
                        break;
                    end
                end

                if(payload_counter == payload_size) begin
                    $fdisplay(log_file, "PAYLOAD OK");
                end else begin
                    payload_error <= 'd1;
                    $fdisplay(log_file, "ERROR: PAYLOAD %d", payload_counter);
                end
            end
           
            // Verificar FCS
            $fdisplay(log_file, "----> FCS <----");
            $fdisplay(log_file, "FCS: %h", fcs);
            calculated_fcs = calculate_crc32(i_rx_array_data, payload_size + 21);
            $fdisplay(log_file, "CALCULATED FCS: %h", calculated_fcs);

            counter = counter + 1;
        end else begin
            preamble_error <= 'd0;
            header_error <= 'd0;
            payload_error <= 'd0;
            fcs_error <= 'd0;
        end
        $fflush(log_file);
    end    

    final begin
        // Cerrar el archivo al finalizar la simulación
        if (log_file != 0) begin
            $fclose(log_file);
        end
    end

    function automatic logic [31:0] calculate_crc32(
        input logic [MAX_FRAME_SIZE-1:0] frame_data,
        input integer frame_size
    );
        // Polinomio CRC-32 (IEEE 802.3)
        localparam logic [32:0] CRC_POLYNOMIAL = 33'h04C11DB7;

        logic [32:0] crc_reg;
        logic [32:0] temp_data;
        integer i;

        crc_reg = 33'hFFFFFFFF;
        for (i = 8; i < frame_size*8; i = i + 1) begin
            temp_data = {frame_data[i], 1'b0} ^ crc_reg;
            for (int j = 0; j < 32; j = j + 1) begin
                if (temp_data[32]) begin
                    temp_data = (temp_data << 1) ^ CRC_POLYNOMIAL;
                end else begin
                    temp_data = temp_data << 1;
                end
            end
            crc_reg = temp_data;
        end

        return ~crc_reg[31:0];
        
    endfunction


endmodule


