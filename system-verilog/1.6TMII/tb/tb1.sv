`include "generator.sv"

module tb1;

    // Parameters
    parameter DATA_WIDTH = 64;                 // Must be a multiple of 8 bits (octets)
    parameter int DATA_CHAR_PROBABILITY = 70;  // Probability in percentage (0-100)
    parameter [7:0] DATA_CHAR_PATTERN = 8'hAA; // Data character pattern
    parameter [7:0] CTRL_CHAR_PATTERN = 8'h55; // Control character pattern
    parameter int ERROR_PROBABILITY = 5;       // Probability of injecting error (0-100)
    parameter int NUM_CYCLES = 2000;           // Number of cycles to run

    // Testbench signals
    logic clk;
    logic i_rst;
    logic [DATA_WIDTH-1:0] o_tx_data;
    logic o_tx_ctrl;

    // Instantiate the generator
    generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(1),
        .IDLE_LENGTH(16),
        .DATA_LENGTH(64),
        .IDLE_CODE(8'h07),
        .START_CODE(8'hFB),
        .EOF_CODE(8'hFD)
    ) dut (
        .clk(clk),
        .i_rst(i_rst),
        .o_tx_data(o_tx_data),
        .o_tx_ctrl(o_tx_ctrl)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Test Sequence
    initial begin
        $dumpfile("tb/tb1.vcd");
        $dumpvars(0, tb1);

        clk = 0;
        i_rst = 1; // Assert reset
        #10;
        i_rst = 0; // Release reset
        
        // Wait for some time to observe output
        #3000;
        
        // Finish the simulation
        $finish;
    end

    // Monitor outputs
    initial begin
        // Apply reset
        rst_n = 0;
        #20;
        rst_n = 1;

        // Run simulation for NUM_CYCLES
        repeat (NUM_CYCLES) @(posedge clk);

        // Finish simulation
        $display("Simulation finished after %0d cycles.", NUM_CYCLES);
        $display("");

        // Calculate error-free counts
        total_data_chars = 0;
        total_ctrl_chars = 0;
        errors_count = 0;

        // Analyze data and control signals
        for (int i = 0; i < NUM_CYCLES; i++) begin

            @(posedge clk);
            // Check for errors
            if (tx_er == 1'b1) begin
                errors_count++;
            end else begin

                for (int j = 0; j < DATA_WIDTH/8; j++) begin
                    if (ctrl_out[j] == 1'b0) begin
                        total_data_chars++;
                    end else begin
                        total_ctrl_chars++;
                    end
                end

            end
        end

        // Display results in table format
        $display("Final Results:");
        $display("|                      |   Received  |");
        $display("| Data Characters      | %11d |", total_data_chars);
        $display("| Control Characters   | %11d |", total_ctrl_chars);
        $display("| Total Characters     | %11d |", total_data_chars + total_ctrl_chars);
        $display("| Total Errors         | %11d |", errors_count);

        $finish;
    end
endmodule
