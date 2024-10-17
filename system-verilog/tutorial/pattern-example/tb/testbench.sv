`include "signal_generator.sv"
`include "signal_checker.sv"
`include "sut.sv"

//iverilog -g2012 -o tb/tb1 tb/testbench.sv
//vvp tb/tb1
//gtkwave tb/simulation.vcd


module testbench();
    // Parameters
    parameter DATA_WIDTH = 64;                 // Must be a multiple of 8 bits (octets)
    parameter int DATA_CHAR_PROBABILITY = 70;  // Probability in percentage (0-100)
    parameter [7:0] DATA_CHAR_PATTERN = 8'hAA; // Data character pattern
    parameter [7:0] CTRL_CHAR_PATTERN = 8'h55; // Control character pattern
    parameter int ERROR_INJECTION_PROBABILITY = 0; // Probability of injecting error (0-100)
    parameter int NUM_CYCLES = 1000;           // Number of cycles to run

    // Testbench signals
    logic clk;
    logic rst_n;
    logic [DATA_WIDTH-1:0] data;
    logic [(DATA_WIDTH/8)-1:0] ctrl;

    // Signals after error injection from DUT
    logic [DATA_WIDTH-1:0] data_err_injected;
    logic [(DATA_WIDTH/8)-1:0] ctrl_err_injected;

    // Signals to capture counts from checker
    logic [31:0] total_char_count;
    logic [31:0] data_char_count;
    logic [31:0] ctrl_char_count;
    logic [31:0] data_error_count;
    logic [31:0] ctrl_error_count;

    // Variables for final calculations (move declarations here)
    int data_error_free;
    int ctrl_error_free;
    int total_error_free;
    int total_errors;

    // Instantiate generator, DUT, and checker modules
    signal_generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_CHAR_PROBABILITY(DATA_CHAR_PROBABILITY),
        .DATA_CHAR_PATTERN(DATA_CHAR_PATTERN),
        .CTRL_CHAR_PATTERN(CTRL_CHAR_PATTERN)
    ) u_generator (
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data),
        .ctrl_out(ctrl)
    );

    sut #(
        .DATA_WIDTH(DATA_WIDTH),
        .ERROR_INJECTION_PROBABILITY(ERROR_INJECTION_PROBABILITY)
    ) u_sut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data),
        .ctrl_in(ctrl),
        .data_out(data_err_injected),
        .ctrl_out(ctrl_err_injected)
    );

    signal_checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_CHAR_PATTERN(DATA_CHAR_PATTERN),
        .CTRL_CHAR_PATTERN(CTRL_CHAR_PATTERN)
    ) u_checker (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_err_injected),
        .ctrl_in(ctrl_err_injected),
        .total_char_count(total_char_count),
        .data_char_count(data_char_count),
        .ctrl_char_count(ctrl_char_count),
        .data_error_count(data_error_count),
        .ctrl_error_count(ctrl_error_count)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // VCD dump
    initial begin
        $dumpfile("tb/simulation.vcd");
        $dumpvars(0, testbench);
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

        // Calculate error-free counts (remove 'int' keyword)
        data_error_free     = data_char_count - data_error_count;
        ctrl_error_free     = ctrl_char_count - ctrl_error_count;
        total_error_free    = total_char_count - (data_error_count + ctrl_error_count);
        total_errors        = data_error_count + ctrl_error_count;

        // Display results in table format
        $display("Final Results:");
        $display("|                      |   Received  |  Error-Free |  With Errors |");
        $display("| Data Characters      | %11d | %11d | %12d |", data_char_count, data_error_free, data_error_count);
        $display("| Control Characters   | %11d | %11d | %12d |", ctrl_char_count, ctrl_error_free, ctrl_error_count);
        $display("| Total Characters     | %11d | %11d | %12d |", total_char_count, total_error_free, total_errors);

        $finish;
    end
endmodule