`include "generator.sv"

// iverilog -g2012 -o tb/tb1 tb/tb1.sv
// vvp tb/tb1
// gtkwave tb/tb1.vcd

module tb1();
    // Parameters
    parameter DATA_WIDTH = 64;                 // Must be a multiple of 8 bits (octets)
    parameter int DATA_CHAR_PROBABILITY = 70;  // Probability in percentage (0-100)
    parameter [7:0] DATA_CHAR_PATTERN = 8'hAA; // Data character pattern
    parameter [7:0] CTRL_CHAR_PATTERN = 8'h55; // Control character pattern
    parameter int ERROR_PROBABILITY = 5;       // Probability of injecting error (0-100)
    parameter int NUM_CYCLES = 1000;           // Number of cycles to run

    // Testbench signals
    logic clk;
    logic rst_n;
    logic [DATA_WIDTH-1:0] data_out;
    logic [(DATA_WIDTH/8)-1:0] ctrl_out;
    logic tx_en;
    logic tx_er;

    // Variables for final calculations
    int total_data_chars;
    int total_ctrl_chars;
    int errors_count;

    // Instantiate generator module
    generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_CHAR_PROBABILITY(DATA_CHAR_PROBABILITY),
        .ERROR_PROBABILITY(ERROR_PROBABILITY),
        .DATA_CHAR_PATTERN(DATA_CHAR_PATTERN),
        .CTRL_CHAR_PATTERN(CTRL_CHAR_PATTERN)
    ) u_generator (
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data_out),
        .ctrl_out(ctrl_out),
        .tx_en(tx_en),
        .tx_er(tx_er)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // VCD dump
    initial begin
        $dumpfile("tb/tb1.vcd");
        $dumpvars(0, tb1);
    end

    // Simulation control
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
            end

            for (int j = 0; j < DATA_WIDTH/8; j++) begin
                if (ctrl_out[j] == 1'b0) begin
                    total_data_chars++;
                end else begin
                    total_ctrl_chars++;
                end
            end
        end

        // Display results in table format
        $display("Final Results:");
        $display("|                      |   Received  |");
        $display("| Data Characters      | %11d |", total_data_chars);
        $display("| Control Characters   | %11d |", total_ctrl_chars);
        $display("| Total Errors         | %11d |", errors_count);

        $finish;
    end
endmodule
