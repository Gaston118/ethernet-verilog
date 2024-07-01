`include "count.v"
`include "shiftreg.v"

module top 
    #(
        parameter NB_LEDS    = 4,
        parameter NB_SW      = 4,
        parameter NB_COUNTER = 32
    )
    (
        output [NB_LEDS - 1 : 0] o_led  ,
        output [NB_LEDS - 1 : 0] o_led_b,
        output [NB_LEDS - 1 : 0] o_leg_g,
        input  [NB_SW   - 1 : 0] i_sw   ,
        input                    i_reset,
        input                    clock     
    );

    wire                   connect_c2sr;
    wire [NB_LEDS - 1 : 0] connect_leds;

    count 
        #(
            .NB_SW      (NB_SW-1   ),
            .NB_COUNTER (NB_COUNTER)
        )
        u_count
        (
            .o_valid (connect_c2sr      ),
            .i_sw    (i_sw[NB_SW-2:0]   ),
            .i_reset (i_reset           ),
            .clock   (clock             )
        );
    
    shiftreg
        #(
            .NB_LEDS (NB_LEDS)
        )
        u_shiftreg
        (
            .o_led   (connect_leds),
            .i_valid (connect_c2sr),
            .i_reset (i_reset     ),
            .clock   (clock       )
        );
        

        assign o_led   = connect_leds;
        assign o_led_b = (i_sw[NB_SW-1]==1'b1) ? connect_leds : 'b0         ;
        assign o_leg_g = (i_sw[NB_SW-1]==1'b1) ? 'b0          : connect_leds;

endmodule