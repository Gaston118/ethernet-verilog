`timescale 1ns/100ps

module mii_checker 
#(
    parameter int DATA_WIDTH = 64,
    parameter int CTRL_WIDTH = 8, 

    parameter [7:0] IDLE_CODE = 8'h07,
    parameter [7:0] START_CODE = 8'hFB,
    parameter [7:0] EOF_CODE = 8'hFD
)
(
    input  logic                  clk,
    input  logic                  i_rst,
    input  logic [DATA_WIDTH-1:0] i_tx_data,
    input  logic [CTRL_WIDTH-1:0] i_tx_ctrl,
    output logic                  o_error  // Error: payload fuera de rango
);

    // Constantes de validación (40 a 136 bytes)
    localparam int MIN_PAYLOAD_BYTES = 40;
    localparam int MAX_PAYLOAD_BYTES = 136;
    localparam int MIN_PAYLOAD_CYCLES = MIN_PAYLOAD_BYTES / (DATA_WIDTH / 8); // 5 ciclos
    localparam int MAX_PAYLOAD_CYCLES = MAX_PAYLOAD_BYTES / (DATA_WIDTH / 8); // 17 ciclos

    typedef enum logic [1:0] {
        WAIT_START = 2'b00,
        COUNT_DATA = 2'b01,
        WAIT_EOF   = 2'b10
    } state_t;

    // Señales internas
    state_t state, next_state;
    int payload_counter, next_payload_counter;  // Contador de ciclos de datos
    logic next_error;
    logic [7:0] start_data_byte;
    logic [7:0] eof_data_byte;
    logic tx_ctrl_bit;

    assign start_data_byte = i_tx_data[7:0];
    assign eof_data_byte   = i_tx_data[63:56];
    assign tx_ctrl_bit  = i_tx_ctrl[0];
    

    // Lógica combinacional para determinar el próximo estado
    always_comb begin
        next_state = state;
        next_payload_counter = payload_counter;
        next_error = 1'b0;

        case (state)
        WAIT_START: begin
            if (start_data_byte == START_CODE && tx_ctrl_bit == 1'b1) begin
                next_state = COUNT_DATA;
                next_payload_counter = 0; // Reinicia el contador de datos
            end
        end

        COUNT_DATA: begin
            if (i_tx_ctrl == 0) begin
                // Incrementa el contador si los datos son válidos
                next_payload_counter = payload_counter + 1;
            end else if (eof_data_byte == EOF_CODE && tx_ctrl_bit == 1'b1) begin
                // Verifica el rango del payload al recibir EOF
                if (payload_counter < MIN_PAYLOAD_CYCLES || payload_counter > MAX_PAYLOAD_CYCLES) begin
                    next_error = 1'b1; // Payload fuera de rango
                end
                next_state = WAIT_START; // Regresa a esperar START
            end
        end

        WAIT_EOF: begin
            // Espera el carácter EOF si el estado anterior no lo detectó
            if (eof_data_byte == EOF_CODE && tx_ctrl_bit == 1'b1) begin
                next_state = WAIT_START;
            end
        end

        endcase
    end

    // Actualización sincrónica de los registros internos
    always_ff @(posedge clk or posedge i_rst) begin
        if (i_rst) begin
            state <= WAIT_START;
            payload_counter <= 0;
            o_error <= 1'b0;
        end else begin
            state <= next_state;
            payload_counter <= next_payload_counter;
            o_error <= next_error;
        end
    end

endmodule
