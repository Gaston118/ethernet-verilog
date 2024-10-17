module sut #(
    parameter DATA_WIDTH = 64,                     // Must be a multiple of 8 bits (octets)
    parameter int ERROR_INJECTION_PROBABILITY = 10 // Probability of injecting error (0-100)
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_WIDTH-1:0]     data_in,
    input  logic [(DATA_WIDTH/8)-1:0] ctrl_in,
    output logic [DATA_WIDTH-1:0]     data_out,
    output logic [(DATA_WIDTH/8)-1:0] ctrl_out
);
    // Internal signals
    logic [DATA_WIDTH-1:0] data_err_injected;
    logic [(DATA_WIDTH/8)-1:0] ctrl_err_injected;
    logic [(DATA_WIDTH/8)-1:0] error_injected_per_char;

    // Declare variables used in error injection
    int rand_num;
    int bit_to_flip;
    int i; // Loop variable

    // Error injection logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_err_injected       <= '0;
            ctrl_err_injected       <= '0;
            error_injected_per_char <= '0;
        end else begin
            // Use blocking assignments for immediate updates
            data_err_injected       = data_in;
            ctrl_err_injected       = ctrl_in;
            error_injected_per_char = '0;

            // For each character, decide whether to inject an error in data
            for (i = 0; i < DATA_WIDTH/8; i++) begin
                rand_num = $urandom_range(0, 99);
                if (rand_num < ERROR_INJECTION_PROBABILITY) begin
                    error_injected_per_char[i] = 1'b1; // Blocking assignment
                    // Flip a random bit in data
                    bit_to_flip = $urandom_range(0, 7); // 0-7 for data bits
                    data_err_injected[i*8 + bit_to_flip] = ~data_err_injected[i*8 + bit_to_flip]; // Blocking assignment
                end
            end
        end
    end

    // Assign outputs
    assign data_out = data_err_injected;
    assign ctrl_out = ctrl_err_injected;
endmodule
