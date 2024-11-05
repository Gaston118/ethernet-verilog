`include "generator.sv"

module tb1;

    // Parameters
    localparam int DATA_WIDTH = 64;
    
    // Signals
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
        $monitor("Time: %0t | o_tx_data: %h | o_tx_ctrl: %b", $time, o_tx_data, o_tx_ctrl);
    end

endmodule
