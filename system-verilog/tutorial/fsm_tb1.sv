`include "fsm.sv"

// Testbench
module fsm_tb1;

reg  clk, a;
wire out1, out2;

// Instantiate device under test
fsm FSM(.clk(clk),
        .a(a),
        .out1(out1),
        .out2(out2));

initial begin
  // Dump waves
  $dumpfile("fsm_tb1.vcd");
  $dumpvars(1, fsm_tb1);

  clk = 0;
  a = 0;
  $display("Initial out1: %0h, out2: %0h",
    out1, out2);

  toggle_clk;
  $display("IDLE out1: %0h, out2: %0h",
    out1, out2);
  
  a = 1;
  toggle_clk;
  $display("STATE_1 out1: %0h, out2: %0h",
    out1, out2);

  toggle_clk;
  $display("FINAL out1: %0h, out2: %0h",
    out1, out2);

  toggle_clk;
  $display("FINAL out1: %0h, out2: %0h",
    out1, out2);
  
  a = 0;
  toggle_clk;
  $display("IDLE out1: %0h, out2: %0h",
    out1, out2);
end

task toggle_clk;
  begin
    #10 clk = ~clk;
    #10 clk = ~clk;
  end
endtask

endmodule