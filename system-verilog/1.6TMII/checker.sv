`timescale 1ns/100ps

module generator_checker
(
    input logic                  clk,
    input logic                  i_rst,
    input logic [DATA_WIDTH-1:0] i_tx_data,
    input logic                  i_tx_ctrl
);

    // Local Parameters
    parameter int DATA_WIDTH = 64;
    parameter [7:0] IDLE_CODE = 8'h07;
    parameter [7:0] START_CODE = 8'hFB;
    parameter [7:0] EOF_CODE = 8'hFD;

    // Internal Signals
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START = 3'b001,
        DATA = 3'b010,
        EOF = 3'b011,
        ERROR = 3'b111
    } state_t;

    state_t current_state, expected_state;

    // Initial State
    initial begin
        current_state = IDLE;
        expected_state = IDLE;
    end

    // Check Outputs
    always_ff @(posedge clk or posedge i_rst) begin
        if (i_rst) begin
            current_state <= IDLE;
            expected_state <= IDLE;
        end else begin
            case (expected_state)
                IDLE: begin
                    if (i_tx_ctrl == 1'b1 && i_tx_data == {DATA_WIDTH{IDLE_CODE}}) begin
                        expected_state <= START;
                    end else begin
                        expected_state <= ERROR;
                    end
                end

                START: begin
                    if (i_tx_ctrl == 1'b1 && i_tx_data == { {DATA_WIDTH - 8{IDLE_CODE}}, START_CODE }) begin
                        expected_state <= DATA;
                    end else begin
                        expected_state <= ERROR;
                    end
                end

                DATA: begin
                    if (i_tx_ctrl == 1'b0 && i_tx_data == {DATA_WIDTH{8'hAA}}) begin
                        expected_state <= EOF;
                    end else begin
                        expected_state <= ERROR;
                    end
                end

                EOF: begin
                    if (i_tx_ctrl == 1'b1 && i_tx_data == {EOF_CODE, {7{IDLE_CODE}}}) begin
                        expected_state <= IDLE;
                    end else begin
                        expected_state <= ERROR;
                    end
                end

                default: expected_state <= IDLE;
            endcase
        end
    end
    
    // Error Output
    initial begin
        if (expected_state == ERROR) begin
            $monitor("Error: Expected %s, Received %s", current_state, expected_state);
        end
    end

endmodule
