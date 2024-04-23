module bitwise_operators();

initial begin
  // Bit Wise Negation
  $display (" ~4'b0001           = %b", (~4'b0001));
  $display (" ~4'bx001           = %b", (~4'bx001));
  $display (" ~4'bz001           = %b", (~4'bz001));
  // Bit Wise AND
  $display (" 4'b0001 &  4'b1001 = %b", (4'b0001 &  4'b1001));
  $display (" 4'b1001 &  4'bx001 = %b", (4'b1001 &  4'bx001));
  $display (" 4'b1001 &  4'bz001 = %b", (4'b1001 &  4'bz001));
  // Bit Wise OR
  $display (" 4'b0001 |  4'b1001 = %b", (4'b0001 |  4'b1001));
  $display (" 4'b0001 |  4'bx001 = %b", (4'b0001 |  4'bx001));
  $display (" 4'b0001 |  4'bz001 = %b", (4'b0001 |  4'bz001));
  // Bit Wise XOR
  $display (" 4'b0001 ^  4'b1001 = %b", (4'b0001 ^  4'b1001));
  $display (" 4'b0001 ^  4'bx001 = %b", (4'b0001 ^  4'bx001));
  $display (" 4'b0001 ^  4'bz001 = %b", (4'b0001 ^  4'bz001));
  // Bit Wise XNOR
  $display (" 4'b0001 ~^ 4'b1001 = %b", (4'b0001 ~^ 4'b1001));
  $display (" 4'b0001 ~^ 4'bx001 = %b", (4'b0001 ~^ 4'bx001));
  $display (" 4'b0001 ~^ 4'bz001 = %b", (4'b0001 ~^ 4'bz001));
  #10 $finish;
end

endmodule