`timescale 1ns / 1ps
`include "top.v"

//iverilog -o tb/tb1 tb/tb1.v
//vvp tb/tb1

module tb1;

    //Parametros
    parameter NB_LEDS    = 4;
    parameter NB_SW      = 4;
    parameter NB_COUNTER = 14;

    reg [NB_SW-1:0] i_sw;
    reg i_reset;
    reg clock;
    wire [NB_LEDS-1:0] o_led, o_led_b, o_led_g;

    top
        #(
            .NB_LEDS    (NB_LEDS   ),
            .NB_SW      (NB_SW     ),
            .NB_COUNTER (NB_COUNTER)
        )
        dut (
        .o_led(o_led),
        .o_led_b(o_led_b),
        .o_leg_g(o_led_g),
        .i_sw(i_sw),
        .i_reset(i_reset),
        .clock(clock)
    );

    // Clock 
    always begin
        #5 clock = ~clock;
    end

    
    initial begin
        $dumpfile("tb/tb1.vcd");
        $dumpvars(0, tb1);
      
        i_reset = 1'b0;
        clock = 1'b1;
        i_sw = 4'b0000;
        #20;

        i_reset = 1'b1;
        #20;

        i_reset = 1'b0;
        #20;

        i_sw = 4'b0001;
        #500;

        $finish;
    end

endmodule
