`timescale 1ns/100ps

module mii_checker 
#(
    parameter int DATA_WIDTH = 64,
    parameter int CTRL_WIDTH = 8, 

    parameter [7:0] IDLE_CODE = 8'h07,
    parameter [7:0] START_CODE = 8'hFB,
    parameter [7:0] TERM_CODE = 8'hFD
)
(
    input  logic                  clk,
    input  logic                  i_rst,
    input  logic [DATA_WIDTH-1:0] i_tx_data,
    input  logic [CTRL_WIDTH-1:0] i_tx_ctrl,
    output logic                  payload_error,  // Error: payload fuera de rango
    output logic                  intergap_error, // Error: intergap insuficiente
    output logic                  other_error    // Error: otros errores
);

    // Constantes de validación (40 a 136 bytes)
    localparam int MIN_PAYLOAD_BYTES = 40;
    localparam int MAX_PAYLOAD_BYTES = 136;
    localparam int MIN_PAYLOAD_CYCLES = MIN_PAYLOAD_BYTES / (DATA_WIDTH / 8); // 5 ciclos
    localparam int MAX_PAYLOAD_CYCLES = MAX_PAYLOAD_BYTES / (DATA_WIDTH / 8); // 17 ciclos

    localparam int MIN_INTERGAP = 16; // 16 Bytes mínimo entre tramas
    localparam int MAX_INTERGAP = 40; // 40 Bytes máximo entre tramas
    localparam int MIN_INTERGAP_CYCLES = MIN_INTERGAP / (DATA_WIDTH / 8); // 2 ciclo
    localparam int MAX_INTERGAP_CYCLES = MAX_INTERGAP / (DATA_WIDTH / 8); // 5 ciclos

    typedef enum logic [1:0] {
        WAIT_START = 2'b00,
        COUNT_DATA = 2'b01,
        CHECK_TERM = 2'b10,
        CHECK_INTERGAP = 2'b11
    } state_t;

    // Señales internas
    state_t state, next_state;
    int payload_counter, next_payload_counter;  // Contador de ciclos de datos
    int intergap_counter, next_intergap_counter; // Contador de ciclos de intergap
    logic o_error, p_error, itg_error; 
    logic [7:0] start_data_byte;
    logic [7:0] term_data_byte;
    logic tx_ctrl_bit;
    int i;

    assign start_data_byte = i_tx_data[7:0];
    assign tx_ctrl_bit  = i_tx_ctrl[0];

    // Lógica combinacional para determinar el próximo estado
    always_comb begin
        next_state = state;
        next_payload_counter = payload_counter;
        next_intergap_counter = intergap_counter;
        o_error = 1'b0;
        p_error = 1'b0;
        itg_error = 1'b0;

        case (state)
        WAIT_START: begin
            if (start_data_byte == START_CODE && tx_ctrl_bit == 1'b1) begin
                next_state = COUNT_DATA;
                next_payload_counter = 0; // Reinicia el contador de datos
            end
        end

        COUNT_DATA: begin
            for(i = 0;i < 8;i = i + 1) begin
                if(i_tx_data[i*8 +: 8] == TERM_CODE && i_tx_ctrl[i] == 1'b1) begin
                    if(payload_counter < MIN_PAYLOAD_CYCLES || payload_counter >    MAX_PAYLOAD_CYCLES) begin
                       p_error = 1'b1;
                    end
                    next_state = CHECK_TERM;
                end else begin
                    next_payload_counter = payload_counter + 1;
                end
            end
        end

        CHECK_TERM: begin
            // Verifica que después del TERM_CODE haya solo IDLE_CODE
            for (i = 0; i < CTRL_WIDTH; i = i + 1) begin
                if (i_tx_ctrl[i] == 1'b1) begin
                    if (i_tx_data[i*8 +: 8] != IDLE_CODE) begin
                        o_error = 1'b1; // Si no es IDLE_CODE, marca un error
                    end else begin
                        next_state = CHECK_INTERGAP; // Cambia al estado de intergap
                        next_intergap_counter = 0; // Reinicia el contador de intergap
                    end
                end
            end
        end
        
        CHECK_INTERGAP: begin
            // Cuenta ciclos hasta que se detecte un nuevo START_CODE
            for (i = 0; i < CTRL_WIDTH; i = i + 1) begin
                if (i_tx_ctrl[i] == 1'b1 && i_tx_data[i*8 +: 8] == START_CODE) begin
                    if (intergap_counter < MIN_INTERGAP_CYCLES || intergap_counter > MAX_INTERGAP_CYCLES) begin
                        itg_error = 1'b1; // Si el intergap es insuficiente o demasiado largo
                    end
                    next_state = COUNT_DATA; // Reinicia la detección de datos
                    next_payload_counter = 0; // Reinicia el contador de payload
                end else begin
                    next_intergap_counter = intergap_counter + 1; // Incrementa el contador
                end
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
            intergap_counter <= next_intergap_counter;
            payload_error <= p_error;
            intergap_error <= itg_error;
            other_error <= o_error;
        end
    end

    // Logger (solo para simulación)
    `ifndef SYNTHESIS
    always @(posedge clk) begin
        if (payload_error) begin
            $display("----------------------------------------------------------");
            $display("[%0t ns] ERROR: Payload fuera de rango detectado", $time);
            $display("Bytes enviados: %0d", payload_counter * (DATA_WIDTH / 8));
            $display("----------------------------------------------------------");
        end
        if (intergap_error) begin
            $display("----------------------------------------------------------");
            $display("[%0t ns] ERROR: Intergap", $time);
            $display("Bytes enviados: %0d", intergap_counter * (DATA_WIDTH / 8));
            $display("----------------------------------------------------------");
        end
        if (other_error) begin
            $display("----------------------------------------------------------");
            $display("[%0t ns] ERROR: Otros errores detectados", $time);
            $display("----------------------------------------------------------");
        end
    end
    `endif

endmodule
