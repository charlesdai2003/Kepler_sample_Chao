//carry lookahead adder with variable size/width
module cla_var #
	(
		SIZE = 8
	)
	(
		input [SIZE-1:0] i_a,
		input [SIZE-1:0] i_b,
		input i_cin,
		output logic [SIZE-1:0] o_sum,
		output o_cout
	);
	
		logic [SIZE:0] w_c;
		logic [SIZE-1:0] w_p;
		logic [SIZE-1:0] w_g;
		
		// first carry is cin
		assign w_c[0] = i_cin;
		
		genvar i;
		generate
			for (i = 0; i < SIZE; i++) begin
				assign o_sum[i] = i_a[i] ^ i_b[i] ^ w_c[i];
				//carry lookahead
				assign w_g[i] = i_a[i] & i_b[i];
				assign w_p[i] = i_a[i] | i_b[i];
				assign w_c[i + 1] = w_g[i] | (w_p[i] & w_c[i]);
			end
		endgenerate
		
		//last carry is cout
		assign o_cout = w_c[SIZE];
endmodule