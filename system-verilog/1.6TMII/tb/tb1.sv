`timescale 1ns/100ps
`include "generator.sv"
`include "checker.sv"

// iverilog -g2012 -o tb/tb1 tb/tb1.sv
// vvp tb/tb1
// gtkwave tb/tb1.vcd

module tb1;

    // Parameters
    localparam int DATA_WIDTH = 64;
    localparam int CTRL_WIDTH = 8;

    // Signals
    logic clk;
    logic i_rst;
    logic [DATA_WIDTH-1:0] o_tx_data;
    logic [CTRL_WIDTH-1:0] o_tx_ctrl;

    // Instantiate the generator module
    generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH)
    ) dut (
        .clk(clk),
        .i_rst(i_rst),
        .o_tx_data(o_tx_data),
        .o_tx_ctrl(o_tx_ctrl)
    );

    // Instantiate the checker module
    generator_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .i_rst(i_rst),
        .i_tx_data(o_tx_data),
        .i_tx_ctrl(o_tx_ctrl)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock
   
    // Test procedure
    initial begin
        $dumpfile("tb/tb1.vcd");
        $dumpvars(0, tb1);

        clk = 0;
        // Initialize signals
        i_rst = 1;
        #10; // Hold reset for 10 ns
        i_rst = 0;

        // Simple output monitoring
        $monitor("Time: %0t | o_tx_data: %h | o_tx_ctrl: %b", $time, o_tx_data, o_tx_ctrl);

        // Run the simulation for a certain period
        #500; // Run for 500 ns

        $finish;
    end

endmodule
