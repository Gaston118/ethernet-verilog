`timescale 1ns / 1ps
`include "top.v"

// CHECKEO DE CORRUPCION DE SECUENCIA Y DESBLOQUEO
//-----------------------------------------------------
// iverilog -o tb/tb3 tb/lfsr_galois_tb3.v
// vvp tb/tb3
// gtkwave tb/lfsr_galois_tb3.vcd
//-----------------------------------------------------

module lfsr_galois_tb3;

  reg clk;
  reg i_valid;
  reg i_rst;
  reg i_soft_reset;
  reg [7:0] i_seed;
  wire o_lock;
  reg i_corrupt;

  top dut (
    .clk(clk),
    .i_valid(i_valid),
    .i_rst(i_rst),
    .i_soft_reset(i_soft_reset),
    .i_seed(i_seed),
    .o_lock(o_lock),
    .i_corrupt(i_corrupt)
  );

  // 10MHz = 100ns

  always #50 clk = ~clk;

initial begin
    $dumpfile("tb/lfsr_galois_tb3.vcd");
    $dumpvars(0, lfsr_galois_tb3);
    
    clk = 0;
    i_valid = 0;
    i_rst = 0;
    i_soft_reset = 0;
    i_seed = 8'h00;
    i_corrupt = 0;

    async_reset;

    #1000;

    change_seed(8'hAA);
    
    soft_reset;

    #1000;

    random_valid;  

    #1000;

    desbloqueo;

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

  task desbloqueo;
    begin
      #100;
      @(posedge clk);
      i_valid = 1;
      #100;
      i_corrupt = 1;
      #2000;
    end
  endtask

endmodule
