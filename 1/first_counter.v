//SPECS 
//4-bit synchronous up counter.
//active high, synchronous reset.
//Active high enable.

// Function : This is a 4 bit up-counter with
// Synchronous active high reset and
// with active high enable signal

module first_counter(
    clock,
    reset,
    enable,
    counter_out
);

input clock, reset, enable;

output [3:0] counter_out ;

wire clock, reset, enable;

reg [3:0] counter_out;

always @(posedge clock)

begin : COUNTER 
    if(reset == 1'b1) 
    begin
        counter_out <=  #1  4'b0000;
    end
    else if (enable == 1'b1) 
    begin
        counter_out <= #1 counter_out + 1;
    end
end

endmodule




