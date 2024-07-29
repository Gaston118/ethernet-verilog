//HAGO TODO GENERICO 

module eth_phy_10g_aligner (
	input wire clk, //Uso el Tx o Rx?
	input wire reset, //Tx o Rx?
	input wire [65:0] data_in,
	output reg [63:0] data_out,
	output reg [1:0] hdr_out,
	output reg aligned
);

	reg [5:0] valid_hdr_count;
	reg [65:0] prev_data;
	reg [65:0] curr_data;
	reg [5:0] hdr_position;
	reg [5:0] i=6'b0;

	localparam IDLE = 1'b0; //Busco los 64 hdrs validos seguidos
	localparam ALIGNED = 1'b1; //Ya encontre los 64 hdrs validos seguidos, paso la data

	// Logica 
	always @(posedge clk or posedge reset) begin
		if (reset) begin

			valid_hdr_count <= 6'b0;
			data_out <= 64'b0;
			hdr_out <= 2'b0;
			aligned <= IDLE;
			prev_data <= 66'b0;
			curr_data <= 66'b0;
			hdr_position <= 6'b0;

		end else begin

		prev_data <= curr_data;
		curr_data <= data_in;

		if (aligned == IDLE) begin	
			if (prev_data[i +: 2] == curr_data[i +: 2] && (curr_data[i +: 2] == 2'b01 || curr_data[i +: 2] == 2'b10)) begin

				valid_hdr_count <= valid_hdr_count + 1;

				if (valid_hdr_count == 6'd63) begin
					aligned <= ALIGNED;
					hdr_position <= i;
				end

			end else begin
				valid_hdr_count <= 6'b0;
				i = i + 1;
			end
		end 

		if (aligned == ALIGNED) begin
			hdr_out <= curr_data[hdr_position +: 2]; //???
			data_out <= curr_data[hdr_position + 2 +: 64]; //Esta bien?
		end

	end

end

endmodule