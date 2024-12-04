module fcs_crc32 (
    input logic clk,
    input logic reset_n,
    input logic [7:0] data_in,  // Entrada de datos (byte)
    input logic data_valid,     // Señal para indicar datos válidos
    input logic fcs_en,         // Habilita el cálculo del FCS
    output logic [31:0] fcs_out // Salida del FCS calculado
);

    // Polinomio CRC-32 (IEEE 802.3)
    localparam logic [31:0] CRC_POLYNOMIAL = 32'h04C11DB7;

    logic [31:0] crc_reg;
    logic [31:0] crc_next;
    integer i;

    always_comb begin
        crc_next = crc_reg;
        if (fcs_en && data_valid) begin
            crc_next = crc_next ^ (data_in << 24);
            for (i = 0; i < 8; i++) begin
                if (crc_next[31]) begin
                    crc_next = (crc_next << 1) ^ CRC_POLYNOMIAL;
                end else begin
                    crc_next = crc_next << 1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            crc_reg <= 32'hFFFFFFFF;
        end else if (fcs_en) begin
            crc_reg <= crc_next;
        end
    end

    // Invertir el CRC según la norma IEEE 802.3
    assign fcs_out = ~crc_reg;

endmodule
