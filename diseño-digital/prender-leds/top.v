module top (
    output [3:0] o_led,
    output [3:0] o_led_b,
    output [3:0] o_led_g,

    input [3:0] i_sw,
    input rst,
    input clk
);

    count 
        u_count
        (
            .o_valid(),
            .i_sw(i_sw[2:0]),
            .rst(rst),
            .clk(clk)
        );
    
    shiftreg
        u_shiftreg
        (
            .o_led(),
            .i_valid(),
            .rst(rst),
            .clk(clk)
        );

endmodule