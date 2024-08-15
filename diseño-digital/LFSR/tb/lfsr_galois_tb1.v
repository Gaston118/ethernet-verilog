`timescale 1ns / 1ps
`include "lfsr_galois.v"

//-----------------------------------------------------
//iverilog -o tb/tb1 tb/lfsr_galois_tb1.v
//vvp tb/tb1
//-----------------------------------------------------

module lfsr_galois_tb1;

  reg clk;
  reg i_valid;
  reg i_rst;
  reg i_soft_reset;
  reg [7:0] i_seed;
  wire [7:0] o_lfsr;

  lfsr_galois dut (
    .clk(clk),
    .i_valid(i_valid),
    .i_rst(i_rst),
    .i_soft_reset(i_soft_reset),
    .i_seed(i_seed),
    .o_lfsr(o_lfsr)
  );

  // 10MHz = 100ns

  always #50 clk = ~clk;

initial begin
    $dumpfile("tb/lfsr_galois_tb1.vcd");
    $dumpvars(0, lfsr_galois_tb1);
    
    clk = 0;
    i_valid = 0;
    i_rst = 0;
    i_soft_reset = 0;
    i_seed = 8'h00;

    async_reset;

    #1000;

    change_seed(8'hAA);
    
    soft_reset;

    #1000;

    random_valid;  

    #1000;

    $finish;
end

  task async_reset;
    reg [7:0] random_reset;
    begin
      random_reset <= $urandom_range(1, 2000);  
      #10;
      $display("Numero: %0d", random_reset);
      i_rst = 1;
      #random_reset; 
      @(posedge clk) i_rst = 0;
    end
  endtask

  task soft_reset;
    reg [7:0] random_soft_reset;
    begin
      random_soft_reset <= $urandom_range(1, 2000); 
      #10; 
      $display("Numero: %0d", random_soft_reset);
      i_soft_reset = 1;
      #random_soft_reset;
      @(posedge clk) i_soft_reset = 0;
    end
  endtask

  task change_seed(input [7:0] seed_value);
    begin
      i_seed = seed_value;
      #10; 
    end
  endtask

  integer i;
  task random_valid;
    begin
      for(i = 0; i < 100; i = i + 1) begin
        @(posedge clk);
        i_valid = $random % 2; // 0 o 1
        #100; 
      end
    end
  endtask

endmodule
