`include "lfsr_galois.v"
`include "lfsr_checker.v"

module top(
    input   wire        clk,          // Reloj del sistema
    input   wire        i_valid,      // Señal de validación para generar nueva secuencia
    input   wire        i_rst,        // Reset asincrónico para inicializar con la semilla fija
    input   wire        i_soft_reset, // Reset sincrónico para inicializar con la semilla del puerto
    input   wire [7:0]  i_seed,       // Semilla inicial proporcionada desde el puerto
    output  wire        o_lock,       // Salida de la secuencia generada 
    input   wire        i_corrupt    // Señal para corromper la secuencia
);

  wire [7:0] lfsr_output;
  wire [7:0] connect_lfsr;

  lfsr_galois u_lfsr_galois(
    .clk(clk),
    .i_valid(i_valid),
    .i_rst(i_rst),
    .i_soft_reset(i_soft_reset),
    .i_seed(i_seed),
    .o_lfsr(lfsr_output)
  );

  assign connect_lfsr = i_corrupt ? {~lfsr_output[7], lfsr_output[6:0]} : lfsr_output;

  lfsr_checker u_lfsr_checker(
    .clk(clk),
    .i_rst(i_rst),
    .i_lfsr(connect_lfsr),
    .i_seed_reg(i_seed),
    .o_lock(o_lock),
    .i_valid(i_valid)
  );

endmodule