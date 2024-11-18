`timescale 1ns/100ps

module generator 
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
    output logic [DATA_WIDTH-1:0] o_tx_data,
    output logic [CTRL_WIDTH-1:0] o_tx_ctrl
);

    // El generador envía entre 8 bytes (1 ciclo) y 160 bytes (20 ciclos)
    // de datos en el estado DATA.

    // 1 byte = 8 bits = 1 octeto.

    // Tamaño del campo MAC Client Data (payload) en un trama Ethernet:
    // Mínimo tamaño de datos: 46 bytes.
    // Máximo tamaño de datos: 1500 bytes.

    // POR AHORA PARA EL CHEKER SOLO VAMOS A VER QUE ESTE ENTRE (40 - 136).
    // LUEGO SE PUEDE CAMBIAR A (46 - 1500).
    // 40 bytes = 5 ciclos de datos.
    // 136 bytes = 17 ciclos de datos.

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
    logic [CTRL_WIDTH-1:0] tx_ctrl, next_tx_ctrl; 
    int data_counter, next_data_counter; 
    int num_data_cycles;

    always_comb begin
        next_state = state;
        next_tx_data = tx_data;
        next_tx_ctrl = tx_ctrl;
        next_data_counter = data_counter;

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
            next_data_counter = 0; // Reinicia el contador de datos
            num_data_cycles = $urandom_range(1, 30); // Número de ciclos de datos
        end
        
        DATA: begin
            next_tx_data = DATA_CHAR_PATTERN;
            next_tx_ctrl = {CTRL_WIDTH{1'b0}}; 
            if (data_counter < num_data_cycles - 1) begin
                next_data_counter = data_counter + 1;
                next_state = DATA;
            end else begin
                next_state = EOF;
            end
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
            data_counter <= 0; // Inicializa el contador en 0
        end else begin
            state <= next_state;
            tx_data <= next_tx_data;
            tx_ctrl <= next_tx_ctrl; // Actualiza el control
            data_counter <= next_data_counter; // Actualiza el contador
        end
    end

    // Output Assignments
    assign o_tx_data = tx_data;
    assign o_tx_ctrl = tx_ctrl; 

endmodule
