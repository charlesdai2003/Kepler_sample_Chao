//enable register with variable size
module reg_var #
	(
		parameter SIZE = 1
	)
	(
		input i_clk,
		input i_en,
		input [SIZE-1:0] i_in,
		output logic [SIZE-1:0] o_out
	);
	
		always_ff @ (posedge i_clk) begin
			if (i_en) o_out <= i_in;
			else o_out <= o_out;
		end
		
endmodule