//unsigned carry save multiplier with variable size/width parameter
module us_csm_var #
	(
		parameter SIZE = 8
	)
	(
		input [SIZE-1:0] i_m,
		input [SIZE-1:0] i_q,
		output [SIZE*2:0] o_p
	);
	
		logic [SIZE-1:0] [SIZE-1:0] w_c;
		logic [SIZE-1:0] [SIZE-1:0] w_sum;
		logic [SIZE-1:0] [SIZE-1:0] w_ands;
		
		//generate ands of m and q
		genvar m;
		genvar q;
		
		generate
			for (m=0; m < SIZE; m++) begin
				for (q=0; q < SIZE; q++) begin
					assign w_ands[m][q] = i_m[m] & i_q[q];
				end
			end
		endgenerate
		
		//generate first row
		genvar i;
		
		generate
			for (i=0; i < SIZE; i++) begin
				fa half_adder (
					.i_a(w_ands[i][0]),
					.i_b(1'b0),
					.i_cin(1'b0),
					.o_sum(w_sum[i][0]),
					.o_cout(w_c[i][0])
				);
			end
		endgenerate
		assign o_p[0] = w_sum [0][0];
		
		//generate rest of the rows
		genvar x;
		genvar y;
		
		generate
			for (x=1; x < SIZE; x++) begin
				assign o_p[x] = w_sum[0][x];
				for (y=0; y < SIZE; y++) begin
					if (y < SIZE -1) begin
						fa full_adder (
							.i_a(w_ands[y][x]),
							.i_b(w_sum[y+1][x-1]),
							.i_cin(w_c[y][x-1]),
							.o_sum(w_sum[y][x]),
							.o_cout(w_c[y][x])
						);
					end
					else begin
						fa full_adder (
							.i_a(w_ands[y][x]),
							.i_b(1'b0),
							.i_cin(w_c[y][x-1]),
							.o_sum(w_sum[y][x]),
							.o_cout(w_c[y][x])
						);
					end
				end
			end
		endgenerate
		
		//sum up last row
		logic [SIZE-1:0] w_la;
		logic [SIZE-1:0] w_lb;
		assign w_la [SIZE-1]= 1'b0;
		assign w_lb [SIZE-1] = w_c[SIZE-1][SIZE-1];
		genvar z;
		generate
			for (z=0;z < SIZE-1; z++) begin
				assign w_la [z] = w_sum[z+1][SIZE-1];
				assign w_lb [z] = w_c[z][SIZE-1];
			end
		endgenerate
		cla_var # (
			.SIZE(SIZE)
		) cla (
			.i_a(w_la),
			.i_b(w_lb),
			.i_cin(1'b0),
			.o_sum(o_p[SIZE*2-1:SIZE]),
			.o_cout(o_p[SIZE*2])
		);
		
endmodule