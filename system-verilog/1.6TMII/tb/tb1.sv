`timescale 1ns/100ps
`include "generator.sv"
`include "mii_checker.sv"

// iverilog -g2012 -o tb/tb1 tb/tb1.sv
// vvp tb/tb1
// gtkwave tb/tb1.vcd

module tb1;

    // Parameters
    localparam int DATA_WIDTH = 64;
    localparam int CTRL_WIDTH = 8;
    localparam int BUFFER_SIZE = 256;

    // Signals
    logic clk;
    logic i_rst_n;
    logic [DATA_WIDTH-1:0] o_tx_data;
    logic [CTRL_WIDTH-1:0] o_tx_ctrl;
    logic other_error, payload_error, intergap_error;
    logic [DATA_WIDTH-1:0] o_captured_data;
    logic o_data_valid;

    // Instantiate the generator module
    generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH)
    ) dut (
        .clk(clk),
        .i_rst_n(i_rst_n),
        .o_tx_data(o_tx_data),
        .o_tx_ctrl(o_tx_ctrl)
    );

    // Instantiate the checker module
    mii_checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH)
    ) uut (
        .clk(clk),
        .i_rst_n(i_rst_n),
        .i_tx_data(o_tx_data),
        .i_tx_ctrl(o_tx_ctrl),
        .payload_error(payload_error),
        .intergap_error(intergap_error),
        .other_error(other_error),
        .o_captured_data(o_captured_data),
        .o_data_valid(o_data_valid)
    );


    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock
   
    // Test procedure
    initial begin
        $dumpfile("tb/tb1.vcd");
        $dumpvars(0, tb1);

        clk = 0;
        // Initialize signals
        i_rst_n = 0;
        #20; // Hold reset for 10 ns
        i_rst_n = 1;

        // Run the simulation for a certain period
        #2000;

        $finish;
    end

endmodule
