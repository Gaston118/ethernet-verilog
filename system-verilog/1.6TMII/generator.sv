module generator #(
    parameter DATA_WIDTH = 64,                 // Must be a multiple of 8 bits (octets)
    parameter int DATA_CHAR_PROBABILITY = 70,  // Probability in percentage (0-100)
    parameter int ERROR_PROBABILITY     = 5,   // Probability of error in percentage 
    parameter [7:0] DATA_CHAR_PATTERN   = 8'hAA, // Pattern for data character
    parameter [7:0] CTRL_CHAR_PATTERN   = 8'h55  // Pattern for control character
)(
    input  logic                         clk,
    input  logic                         rst_n,
    output logic [DATA_WIDTH-1:0]        data_out,
    output logic [(DATA_WIDTH/8)-1:0]    ctrl_out,
    output logic                         tx_en,    // Transmit Enable
    output logic                         tx_er     // Transmit Error
);

    int random_char;
    int random_error;
    logic error_detected;  // Flag to indicate if an error is detected

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= '0;
            ctrl_out <= '0;
            tx_en    <= 1'b0;
            tx_er    <= 1'b0;
        end else begin
            tx_en <= 1'b1;
            error_detected = 1'b0;  // Reset error flag for each cycle

            for (int i = 0; i < DATA_WIDTH/8; i++) begin
              
                random_error = $urandom_range(0, 99);

                if (random_error < ERROR_PROBABILITY) begin
                    error_detected = 1'b1;  
                    data_out[i*8 +: 8] <= ~DATA_CHAR_PATTERN; 
                    ctrl_out[i]        <= 1'b0;               

                end else begin
                    random_char = $urandom_range(0, 99);

                    if (random_char < DATA_CHAR_PROBABILITY) begin
                        data_out[i*8 +: 8] <= DATA_CHAR_PATTERN;
                        ctrl_out[i]        <= 1'b0;  // Data character

                    end else begin
                        data_out[i*8 +: 8] <= CTRL_CHAR_PATTERN;
                        ctrl_out[i]        <= 1'b1;  // Control character
                    end
                end
            end

            // Set the transmit error flag at the end of the loop
            tx_er <= error_detected;
        end
    end
endmodule
