
module lfsr_galois(
  input   wire        clk,          // Reloj del sistema
  input   wire        i_valid,      // Señal de validación para generar nueva secuencia
  input   wire        i_rst,        // Reset asincrónico para inicializar con la semilla fija
  input   wire        i_soft_reset, // Reset sincrónico para inicializar con la semilla del puerto
  input   wire [7:0]  i_seed,       // Semilla inicial proporcionada desde el puerto
  output  wire [7:0]  o_lfsr        // Salida de la secuencia generada
);

// Registro para el estado actual del LFSR
reg [7:0] lfsr_reg;

// Registro para la semilla fija
reg [7:0] seed_reg = 8'b00000001;

// Feedback del LFSR
wire feedback = lfsr_reg[7] ^ (lfsr_reg[6:0]==7'b0000000);

always @(posedge clk or posedge i_rst) begin

  if(i_rst) begin

    lfsr_reg <= seed_reg;

  end else if(i_soft_reset) begin

    lfsr_reg <= i_seed;

  end else if(i_valid) begin

    lfsr_reg[0] <= feedback;
    lfsr_reg[1] <= lfsr_reg[0];
    lfsr_reg[2] <= lfsr_reg[1]^feedback;
    lfsr_reg[3] <= lfsr_reg[2]^feedback;
    lfsr_reg[4] <= lfsr_reg[3]^feedback;
    lfsr_reg[5] <= lfsr_reg[4];
    lfsr_reg[6] <= lfsr_reg[5];
    lfsr_reg[7] <= lfsr_reg[6];

  end

end

assign o_lfsr = lfsr_reg;

endmodule


