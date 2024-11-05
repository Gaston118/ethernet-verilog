`timescale 1ns/100ps

module generator 
#(
    /*
    *---------WIDTH---------
    */
    parameter int DATA_WIDTH = 64,
    parameter int CTRL_WIDTH = 8,  // Cambiado a 1 bit
    /*
    *---------LENGTH---------
    */
    parameter [7:0] IDLE_CODE = 8'h07,
    parameter [7:0] START_CODE = 8'hFB,
    parameter [7:0] EOF_CODE = 8'hFD
)
(
    input  logic                  clk,
    input  logic                  i_rst,
    output logic [DATA_WIDTH-1:0] o_tx_data,
    output logic [CTRL_WIDTH-1:0] o_tx_ctrl
);

    // Local Parameters
    localparam [DATA_WIDTH-1:0] DATA_CHAR_PATTERN = {DATA_WIDTH{8'hAA}};
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        START = 2'b01,
        DATA = 2'b10,
        EOF = 2'b11
    } state_t;

    // Internal Signals
    state_t state, next_state;
    logic [DATA_WIDTH-1:0] tx_data, next_tx_data;
    logic [CTRL_WIDTH-1:0] tx_ctrl, next_tx_ctrl; // Control signal como un solo bit

    // State Transition Logic
    always_comb begin
        next_state = state;
        next_tx_data = tx_data;
        next_tx_ctrl = tx_ctrl; // Inicializa el next_tx_ctrl con el valor actual

        case (state)
        IDLE: begin
            next_tx_data = {DATA_WIDTH{IDLE_CODE}}; // Siempre emite el IDLE_CODE
            next_tx_ctrl = 1'b1; // Control de IDLE es 1
            next_state = START;  // Cambia a START inmediatamente
        end

        START: begin
            next_tx_data = { {DATA_WIDTH - 8{IDLE_CODE}}, START_CODE };
            next_tx_ctrl = 1'b1; // Control de START es 1
            next_state = DATA;
        end

        DATA: begin
            next_tx_data = DATA_CHAR_PATTERN;
            next_tx_ctrl = 1'b0; // Todos los bytes son datos, control es 0
            next_state = EOF;
        end          

        EOF: begin
            next_tx_data = {EOF_CODE, {7{IDLE_CODE}}};
            next_tx_ctrl = 1'b1; // Control de EOF es 1
            next_state = IDLE; // Regresa al estado IDLE
        end

        endcase
    end

    // Synchronous State Update
    always_ff @(posedge clk or posedge i_rst) begin
        if (i_rst) begin
            state <= IDLE;
            tx_data <= {DATA_WIDTH{1'b0}};
            tx_ctrl <= 1'b0; // Inicializa el control en 0
        end else begin
            state <= next_state;
            tx_data <= next_tx_data;
            tx_ctrl <= next_tx_ctrl; // Actualiza el control
        end
    end

    // Output Assignments
    assign o_tx_data = tx_data;
    assign o_tx_ctrl = tx_ctrl; // Salida de control de un solo bit

endmodule
