`include "lfsr_galois.v"
`include "lfsr_checker.v"

module top(
    input   wire        clk        // Reloj del sistema
//    input   wire        i_valid,      
//    input   wire        i_rst,        
//    input   wire        i_soft_reset, 
//    input   wire [7:0]  i_seed,       
//    output  wire        o_lock,       
//    input   wire        i_corrupt   
);

   wire        i_valid;         // Señal de validación para generar nueva secuencia
   wire        i_rst;           // Reset asincrónico para inicializar con la semilla fija
   wire        i_soft_reset;    // Reset sincrónico para inicializar con la semilla del puerto
   wire [7:0]  i_seed;          // Semilla inicial proporcionada desde el puerto
   wire        o_lock;          // Salida de la secuencia generada 
   wire        i_corrupt;       // Señal para corromper la secuencia

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
  
  vio
  u_vio
   (
    .clk_0(clk),
    .probe_in0_0(o_lock),
    .probe_out0_0(i_rst),
    .probe_out1_0(i_soft_reset),
    .probe_out2_0(i_valid),
    .probe_out3_0(i_seed),
    .probe_out4_0(i_corrupt)
    );
    
    ila
    u_ila
   (
    .clk_0(clk),
    .probe0_0(o_lock),
    .probe1_0(connect_lfsr)
    );

endmodule