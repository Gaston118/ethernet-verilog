`timescale 1ns/1ps

module tb2;

    // Parameters
    localparam PAYLOAD_LENGTH   = 50;
    localparam CLK_PERIOD       = 10;  // 100 MHz clock
    localparam PAYLOAD_MAX_SIZE = 64;
    localparam DATA_WIDTH       = 64;
    localparam CTRL_WIDTH       = 8;
    localparam FCS_WIDTH        = 32;
    localparam IDLE_CODE        = 8'h07;
    localparam START_CODE       = 8'hFB;
    localparam TERM_CODE        = 8'hFD;
    localparam PREAMBLE_CODE    = 8'h55;
    localparam SFD_CODE         = 8'hD5;
    localparam DST_ADDR_CODE    = 48'hFFFFFFFFFFFF;
    localparam SRC_ADDR_CODE    = 48'h123456789ABC;
    localparam int MIN_PAYLOAD_BYTES = 46;
    localparam int MAX_PAYLOAD_BYTES = 1500;
    localparam int MAX = MIN_PAYLOAD_BYTES + MAX_PAYLOAD_BYTES;

    // Signals
    reg clk;
    reg i_rst_n;
    reg i_start;
    reg [47:0] i_dest_address;
    reg [47:0] i_src_address;
    reg [15:0] i_eth_type;
    reg [15:0] i_payload_length;
    reg [7:0] i_payload[PAYLOAD_LENGTH-1:0];
    reg [7:0] i_interrupt;
    wire [63:0] o_mii_data;
    wire [7:0] o_mii_valid;
    wire valid;

    logic other_error, payload_error, intergap_error;
    logic preamble_error, fcs_error, header_error, payload_error_mac;
    wire valid_mac;
    logic [DATA_WIDTH-1:0] captured_data;
    logic [DATA_WIDTH-1:0] buffer_data[0:255];
    logic [650-1:0] array_data;

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Instantiate DUT
    mac_mii_top #(
        .PAYLOAD_MAX_SIZE(PAYLOAD_MAX_SIZE),
        .PAYLOAD_LENGTH(PAYLOAD_LENGTH)
    ) dut (
        .clk(clk),
        .i_rst_n(i_rst_n),
        .i_start(i_start),
        .i_dest_address(i_dest_address),
        .i_src_address(i_src_address),
        .i_eth_type(i_eth_type),
        .i_payload_length(i_payload_length),
        .i_payload(i_payload),
        .i_interrupt(i_interrupt),
        .o_txValid (valid),
        .o_mii_data(o_mii_data),
        .o_mii_valid(o_mii_valid)
    );

    mii_checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .IDLE_CODE(IDLE_CODE),
        .START_CODE(START_CODE),
        .TERM_CODE(TERM_CODE)
    ) dut_checker_mii (
        .clk(clk),
        .i_rst_n(i_rst_n),
        .i_tx_data(o_mii_data),
        .i_tx_ctrl(o_mii_valid),
        .payload_error(payload_error),
        .intergap_error(intergap_error),
        .other_error(other_error),
        .o_captured_data(captured_data),
        .o_data_valid(valid_mac),
        .o_buffer_data(buffer_data),
        .o_array_data(array_data)
    );

    mac_checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .FCS_WIDTH(FCS_WIDTH),
        .IDLE_CODE(IDLE_CODE),
        .START_CODE(START_CODE),
        .TERM_CODE(TERM_CODE),
        .PREAMBLE_CODE(PREAMBLE_CODE),
        .SFD_CODE(SFD_CODE),
        .DST_ADDR_CODE(DST_ADDR_CODE),
        .SRC_ADDR_CODE(SRC_ADDR_CODE)
    ) dut_checker_mac (
        .clk(clk),
        .i_rst_n(i_rst_n),
        .i_rx_data(buffer_data),
        .i_rx_array_data(array_data),
        .i_rx_ctrl(o_mii_valid),
        .i_data_valid(valid_mac),
        .preamble_error(preamble_error),
        .fcs_error(fcs_error),
        .header_error(header_error),
        .payload_error(payload_error_mac)
    );

    // Testbench logic
    initial begin
        // Initialize inputs
        i_rst_n = 0;
        i_start = 0;
        i_dest_address = 48'hFFFFFFFFFFFF;  // Broadcast address
        i_src_address = 48'h123456789ABC;   // Example source address
        i_eth_type = 16'h0800;              
        i_payload_length = PAYLOAD_LENGTH;
        i_interrupt = 8'd0;                // No interrupt
        
        // // Initialize payload data
        // i_payload[0] = 8'hDE;
        // i_payload[1] = 8'hAD;
        // i_payload[2] = 8'hBE;
        // i_payload[3] = 8'hEF;
        // i_payload[4] = 8'hCA;
        // i_payload[5] = 8'hFE;
        // i_payload[6] = 8'hBA;
        // i_payload[7] = 8'hBE;

        for (int i = 0; i < 64; i++) begin
            i_payload[i] = 8'h00; // Initialize all payload bytes to zero
        end

        // Reset the system
        #20;
        i_rst_n = 1;

        preload_payload(50, '{8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE,
                              8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE,
                              8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE,
                              8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE,
                              8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE }); // Preload payload
        i_payload_length = 8; // Payload length = 6 bytes
        i_start = 1; // Trigger frame generation
        repeat (70)@(posedge clk);
        i_start = 0; // Deassert start


        // // Start frame generation
        // #10;
        // i_start = 1;
        // #CLK_PERIOD;
        // i_start = 0;

        // Wait for frame to complete
        repeat (10) @(posedge clk);

        // End simulation
        $stop;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | MII Data: %h | MII Valid: %b", $time, o_mii_data, o_mii_valid);
    end




    // Task to preload the payload array
task preload_payload(input int len, input byte payload_data[]);
for (int i = 0; i < len; i++) begin
    i_payload[i] = payload_data[i];
end
endtask


endmodule

