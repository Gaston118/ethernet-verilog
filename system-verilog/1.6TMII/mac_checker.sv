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
    parameter [47:0] DST_ADDR_CODE  = 48'h0180C2000001,
    parameter [47:0] SRC_ADDR_CODE  = 48'h5A5152535455,
    parameter [15:0] LEN_TYP_CODE   = 16'h8808
)
(
    input logic                  clk,
    input logic                  i_rst,
    input logic [DATA_WIDTH-1:0] i_rx_data,
    input logic [CTRL_WIDTH-1:0] i_rx_ctrl,
    input logic [FCS_WIDTH-1:0]  i_rx_fcs,
    output logic                 frame_error,
    output logic                 fcs_error,   
    output logic                 format_error
);

    // Parámetros de los tamaños de los campos en bytes 
    localparam int PREAMBLE_SIZE        = 7;    // PREAMBLE STATE
    localparam int SFD_SIZE             = 1;    // PREAMBLE STATE
    localparam int DA_SIZE              = 6;    // HEADER STATE
    localparam int SA_SIZE              = 6;    // HEADER STATE
    localparam int LENGTH_TYPE          = 2;    // HEADER STATE
    localparam int FCS_SIZE             = 4;    // FCS STATE
    localparam int MIN_MAC_CLIENT_DATA  = 46;   // PAYLOAD STATE
    localparam int MAX_MAC_CLIENT_DATA  = 1504; // PAYLOAD STATE

    localparam int MIN_FRAME_SIZE       = 64;
    localparam int MAX_FRAME_SIZE       = 1518;

    typedef enum logic [2:0] {
        WAIT_START  = 3'b000,
        PREAMBLE    = 3'b001,
        HEADER      = 3'b010,
        PAYLOAD     = 3'b011,
        FCS         = 3'b100
    } state_t;

    state_t state, next_state;

    logic [7:0] start_data_byte;
    logic [7:0] sfd_data_byte;
    logic tx_ctrl_bit;

    assign start_data_byte = i_rx_data[7:0];
    assign tx_ctrl_bit  = i_rx_ctrl[0];
    assign sfd_data_byte = i_rx_data[63:56];

    logic [127:0] shift_register; // 16 bytes
    int next_payload_size, payload_size;                  
    logic valid_preamble, valid_header, valid_payload, valid_fcs;
    logic invalid_preamble, invalid_header, invalid_payload, invalid_fcs;
    int i, j, k;
    logic found_fcs;

    always_comb begin
        next_state = state;
        next_payload_size = payload_size;

        case (state)
            // Solo esperamos el start para pasar al estado de preámbulo
            WAIT_START: begin
                if (start_data_byte == START_CODE && tx_ctrl_bit == 1'b1) begin
                    next_state = PREAMBLE;
                    valid_preamble = 1'b0;
                    invalid_preamble = 1'b0;
                end
            end

            // Chekeamos el preambulo y el SFD
            PREAMBLE: begin
                for (i = 0; i < 7; i = i + 1) begin
                    if(i_rx_data[i*8 +: 8] == PREAMBLE_CODE && sfd_data_byte == SFD_CODE) begin
                        valid_preamble = 1'b1;
                        invalid_preamble = 1'b0;
                        valid_header = 1'b0;
                        invalid_header = 1'b0;
                        next_state = HEADER;
                    end else begin
                        invalid_preamble = 1'b1;
                        next_state = WAIT_START;
                    end
                end
            end

            // Chekeamos la dirección de destino, la dirección de origen y el tipo/longitud
            HEADER: begin
                for (j = 0; j < 14; j = j + 1) begin
                    if (j < 6) begin
                        if (i_rx_data[j*8 +: 8] != DST_ADDR_CODE) begin
                            invalid_header = 1'b1;
                            next_state = WAIT_START;
                        end
                    end  else if (j > 6 && j < 12) begin
                        if (i_rx_data[j*8 +: 8] != SRC_ADDR_CODE) begin
                            invalid_header = 1'b1;
                            next_state = WAIT_START;
                        end
                    end else begin
                        if (i_rx_data[j*8 +: 8] != LEN_TYP_CODE) begin
                            invalid_header = 1'b1;
                            next_state = WAIT_START;
                        end
                    end

                    if (!invalid_header) begin
                        valid_header = 1'b1;
                        payload_size = 2; // POR QUE YA TENEMOS 2 BYTES
                        valid_payload = 1'b0;
                        invalid_payload = 1'b0;
                        next_state = PAYLOAD;
                    end
                end
            end

            // Chekeamos el payload
            PAYLOAD: begin
                found_fcs = 1'b0;
                next_payload_size = payload_size;

                for (k = 0; k < 8; k = k + 1) begin
                    if (!found_fcs) begin
                        // Verificar cuando comienza el FCS
                        
                        if (i_rx_data[k*8 +: FCS_WIDTH] == i_rx_fcs) begin
                            next_payload_size = payload_size + i; 
                            found_fcs = 1'b1; 
                        end
                    end
                end

                if (found_fcs) begin
                    if (payload_size < MIN_MAC_CLIENT_DATA || payload_size > MAX_MAC_CLIENT_DATA) begin
                        invalid_payload = 1'b1;
                        next_state = WAIT_START;
                    end
                    valid_payload = 1'b1;
                    invalid_payload = 1'b0;
                    valid_fcs = 1'b0;
                    invalid_fcs = 1'b0;
                    next_state = FCS;
                end else begin
                    next_payload_size = payload_size + 8;
                    next_state = PAYLOAD;
                end
            end

            // Chekeamos el FCS que tenemos como dato en la trama con el que recibimos de i_rx_fcs de nuestro otro modulo
            FCS: begin
                
            end

            default: next_state = WAIT_START;
        endcase
    end

    always_ff @(posedge clk or posedge i_rst) begin
        if (i_rst) begin
            state <= WAIT_START;
            payload_size <= 0;
        end else begin
            state <= next_state;
            payload_size <= next_payload_size;
        end
    end

endmodule