`timescale 1ns/100ps

module generator 
#(
    parameter int DATA_WIDTH = 64, // Tamaño de datos = 64 bits
    parameter int CTRL_WIDTH = 8, // Tamaño de control = 8 bits
    parameter [7:0] IDLE_CODE = 8'h07, // Código de IDLE
    parameter [7:0] START_CODE = 8'hFB, // Código de START
    parameter [7:0] TERM_CODE = 8'hFD // Código de TERMINATE
)
(
    input  logic                  clk,
    input  logic                  i_rst,
    output logic [DATA_WIDTH-1:0] o_tx_data,
    output logic [CTRL_WIDTH-1:0] o_tx_ctrl
);

    localparam [DATA_WIDTH-1:0] DATA_CHAR_PATTERN = {DATA_WIDTH{8'hAA}};

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        PAYLOAD = 2'b01
    } state_t;

    // Señales internas
    state_t state, next_state;
    logic [DATA_WIDTH-1:0] tx_data, next_tx_data;
    logic [CTRL_WIDTH-1:0] tx_ctrl, next_tx_ctrl; 
    int data_counter, next_data_counter; 
    int ctrl_counter, next_ctrl_counter;
    int num_data_cycles;
    int num_intergap;
    int fd_position;
    int remaining_bits;
    logic [DATA_WIDTH-1:0] temp_data;
    logic [CTRL_WIDTH-1:0] temp_ctrl;

    always_comb begin
        next_state = state;
        next_tx_data = tx_data;
        next_tx_ctrl = tx_ctrl;
        next_data_counter = data_counter;
        next_ctrl_counter = ctrl_counter;

        case (state)
        IDLE: begin
            // Enviar solo caracteres IDLE
            next_tx_data = {DATA_WIDTH{IDLE_CODE}};
            next_tx_ctrl = {CTRL_WIDTH{1'b1}};
            if (ctrl_counter < num_intergap) begin
                next_ctrl_counter = ctrl_counter + 1;
                next_state = IDLE;
            end else begin
                next_ctrl_counter = 0; 
                next_state = PAYLOAD;  
                num_data_cycles = $urandom_range(1, 20); 
            end  
        end
        
        PAYLOAD: begin
            // Enviar START_CODE en el primer ciclo
            if (data_counter == 0) begin
                next_tx_data = {DATA_CHAR_PATTERN[DATA_WIDTH-9:0], START_CODE};
                next_tx_ctrl = {{CTRL_WIDTH-1{1'b0}}, 1'b1};
                next_data_counter = data_counter + 1;
            end
            // Continuar enviando datos mientras el contador sea menor
            else if (data_counter < num_data_cycles) begin
                next_tx_data = DATA_CHAR_PATTERN;
                next_tx_ctrl = {CTRL_WIDTH{1'b0}};
                next_data_counter = data_counter + 1;
            end
            // Los datos pueden terminar en cualquier parte de los 8 bytes
            // Se rellena con idle si es necesario.
            else begin
                fd_position = $urandom_range(0, 7);
                
                // Generar el patrón de salida basado en `fd_position`
                for (int i = 0; i < DATA_WIDTH/8; i++) begin
                    if (i < fd_position) begin
                        temp_data[i*8 +: 8] = DATA_CHAR_PATTERN[i*8 +: 8]; // Datos
                    end else if (i == fd_position) begin
                        temp_data[i*8 +: 8] = TERM_CODE; // Código de término
                    end else begin
                        temp_data[i*8 +: 8] = IDLE_CODE; // Idle
                    end
                end

                next_tx_data = temp_data;

                // Generar el control correspondiente
                for (int i = 0; i < CTRL_WIDTH; i++) begin
                    if (i == fd_position) begin
                        temp_ctrl[i] = 1'b1; // Indicar control en `fd_position`
                    end else begin
                        temp_ctrl[i] = 1'b0;
                    end
                end

                next_tx_ctrl = temp_ctrl;

                // Terminar transmisión y regresar a estado IDLE
                next_data_counter = 0;
                next_state = IDLE;
                num_intergap = $urandom_range(1, 8); // Nueva pausa aleatoria
            end   
        end     
    endcase
end

    // Actualización síncrona
    always_ff @(posedge clk or posedge i_rst) begin
        if (i_rst) begin
            state <= IDLE;
            tx_data <= {DATA_WIDTH{1'b0}};
            tx_ctrl <= {CTRL_WIDTH{1'b0}};
            data_counter <= 0; 
            ctrl_counter <= 0;
        end else begin
            state <= next_state;
            tx_data <= next_tx_data;
            tx_ctrl <= next_tx_ctrl; 
            data_counter <= next_data_counter; 
            ctrl_counter <= next_ctrl_counter; 
        end
    end

    // Asignaciones de salida
    assign o_tx_data = tx_data;
    assign o_tx_ctrl = tx_ctrl; 

endmodule
