module lfsr_checker(
  input  wire         clk,        
  input  wire         i_rst,      
  input  wire  [7:0]  i_lfsr,
  input  wire  [7:0]  i_seed_reg, 
  output wire         o_lock   
);

  reg [7:0] expected_lfsr;

  reg [2:0] valid_count;
  reg [1:0] invalid_count;

  reg lock;

  wire feedback = expected_lfsr[7] ^ (expected_lfsr[6:0] == 7'b0000000);
  wire i_feedback = i_lfsr[7] ^ (i_lfsr[6:0] == 7'b0000000);

  always @(posedge clk or posedge i_rst) begin
    if (i_rst) begin

      expected_lfsr <= i_seed_reg;
      lock          <= 0;
      valid_count   <= 0;
      invalid_count <= 0;

    end else begin

      if (i_lfsr == expected_lfsr) begin
      
      expected_lfsr[0] <= feedback;
      expected_lfsr[1] <= expected_lfsr[0];
      expected_lfsr[2] <= expected_lfsr[1] ^ feedback;
      expected_lfsr[3] <= expected_lfsr[2] ^ feedback;
      expected_lfsr[4] <= expected_lfsr[3] ^ feedback;
      expected_lfsr[5] <= expected_lfsr[4];
      expected_lfsr[6] <= expected_lfsr[5];
      expected_lfsr[7] <= expected_lfsr[6];

      valid_count <= valid_count + 1;
      invalid_count <= 0;

      if (valid_count >= 5) begin
        lock <= 1'b1;
      end

      end else begin

        expected_lfsr[0] <= i_feedback;
        expected_lfsr[1] <= i_lfsr[0];
        expected_lfsr[2] <= i_lfsr[1] ^ i_feedback;
        expected_lfsr[3] <= i_lfsr[2] ^ i_feedback;
        expected_lfsr[4] <= i_lfsr[3] ^ i_feedback;
        expected_lfsr[5] <= i_lfsr[4];
        expected_lfsr[6] <= i_lfsr[5];
        expected_lfsr[7] <= i_lfsr[6];

        invalid_count <= invalid_count + 1;
        valid_count <= 0;
        
        if (invalid_count >= 3) begin
          lock <= 1'b0;
        end

      end

    end
  end

  assign o_lock = lock;

endmodule
