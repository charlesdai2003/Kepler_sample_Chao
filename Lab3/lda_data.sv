//datapath of LDA
module lda_data (
	input [8:0] i_x0,
	input [7:0] i_y0,
	input [8:0] i_x1,
	input [7:0] i_y1,
	input i_clk,
	input i_reset,
	input i_set_steep,
	input i_set_x0gtx1,
	input i_set_params,
	input i_set_x0x1y0y1,
	input i_init,
	input i_upd_err,
	input i_upd_xy,
	output logic o_xgtx0,
	output logic [8:0] o_x,
	output logic [7:0] o_y
	);
	
	logic [8:0] x0;
	logic [7:0] y0;
	logic [8:0] x1;
	logic [7:0] y1;
	logic [7:0] y1my0;
	logic [7:0] abs_y1my0;
	logic [8:0] x1mx0;
	logic [8:0] abs_x1mx0;
	logic [8:0] deltax;
	logic [7:0] deltay;
	logic steep;
	logic steepsave;
	logic x0gtx1;
	logic ystep;

	x0x1y0y1 xy01 (
	.i_reset(i_reset),
	.i_x0(i_x0),
	.i_x1(i_x1),
	.i_y0(i_y0),
	.i_y1(i_y1),
	.i_set_x0x1y0y1(i_set_x0x1y0y1),
	.i_set_steep(i_set_steep),
	.i_steep(steep),
	.i_set_x0gtx1(i_set_x0gtx1),
	.i_x0gtx1(x0gtx1),
	.i_clk(i_clk),
	.o_x0(x0),
	.o_x1(x1),
	.o_y0(y0),
	.o_y1(y1),
	.o_steepsave(steepsave)
	);
	
	y1my0 suby (
	.i_y0(y0),
	.i_y1(y1),
	.o_y1my0(y1my0),
	.o_abs_y1my0(abs_y1my0)
	);
	
	x1mx0 subx (
	.i_x0(x0),
	.i_x1(x1),
	.o_x1mx0(x1mx0),
	.o_abs_x1mx0(abs_x1mx0)
	);
	
	comp_steep compsteep (
	.i_abs_y1my0(abs_y1my0),
	.i_abs_x1mx0(abs_x1mx0),
	.o_steep(steep)
	);
	
	comp_x0gtx1 compx0gtx1 (
	.i_x0(x0),
	.i_x1(x1),
	.o_x0gtx1(x0gtx1)
	);
	
	params_reg params (
	.i_x1mx0(x1mx0),
	.i_abs_y1my0(abs_y1my0),
	.i_y0(y0),
	.i_y1(y1),
	.i_set_params(i_set_params),
	.i_clk(i_clk),
	.i_reset(i_reset),
	.o_deltax(deltax),
	.o_deltay(deltay),
	.o_ystep(ystep)
	);
	
	xy manip_xy (
	.o_x(o_x),
	.o_y(o_y),
	.o_xgtx0(o_xgtx0),
	.i_clk(i_clk),
	.i_reset(i_reset),
	.i_init(i_init),
	.i_ystep(i_ystep),
	.i_upd_err(i_upd_err),
	.i_upd_xy(i_upd_xy),
	.i_deltax(deltax),
	.i_deltay(deltay),
	.i_x0(x0),
	.i_y0(y0),
	.steep(steepsave)
	);
endmodule

//sets and manipulates x0x1y0y1
module x0x1y0y1 (
	input i_reset,
	input [8:0] i_x0,
	input [8:0] i_x1,
	input [7:0] i_y0,
	input [7:0] i_y1,
	input i_set_x0x1y0y1,
	input i_set_steep,
	input i_steep,
	input i_set_x0gtx1,
	input i_x0gtx1,
	input i_clk,
	output logic [8:0] o_x0,
	output logic [8:0] o_x1,
	output logic [7:0] o_y0,
	output logic [7:0] o_y1,
	output logic o_steepsave
	);
	
	logic [8:0] x0;
	logic [8:0] x1;
	logic [7:0] y0;
	logic [7:0] y1;
	
	always_ff @ (posedge i_clk) begin
		if (i_reset) begin
			o_x0 <= 9'b0;
			o_x1 <= 9'b0;
			o_y0 <= 8'b0;
			o_y1 <= 8'b0;
			x0 <= 9'b0;
			x1 <= 9'b0;
			y0 <= 8'b0;
			y1 <= 8'b0;
			o_steepsave <= 1'b0;
		end
		else if (i_set_x0x1y0y1) begin
			o_x0 <= i_x0;
			o_x1 <= i_x1;
			o_y0 <= i_y0;
			o_y1 <= i_y1;
			x0 <= i_x0;
			x1 <= i_x1;
			y0 <= i_y0;
			y1 <= i_y1;
		end
		else if (i_steep & i_set_steep) begin
			o_x0 <= y0;
			o_x1 <= y1;
			o_y0 <= x0;
			o_y1 <= x1;
			o_steepsave <= i_steep;
		end
		else if (i_set_x0gtx1 & i_x0gtx1) begin
			o_x0 <= x1;
			o_x1 <= x0;
			o_y0 <= y1;
			o_y1 <= y0;
		end
		else begin
			o_x0 <= o_x0;
			o_x1 <= o_x1;
			o_y0 <= o_y0;
			o_y1 <= o_y1;
			x0 <= x0;
			x1 <= x1;
			y0 <= y0;
			y1 <= y1;
			o_steepsave <= o_steepsave;
		end
	end
endmodule

//get regular and abs values of y1 - y0
module y1my0 (
	input [7:0] i_y0,
	input [7:0] i_y1,
	output logic [7:0] o_y1my0,
	output logic [7:0] o_abs_y1my0
	);
	
	always_comb begin
		o_y1my0 = i_y1 - i_y0;
		if (o_y1my0[7] == 1'b1) begin
			o_abs_y1my0 = -o_y1my0;
		end
		else begin
			o_abs_y1my0 = o_y1my0;
		end
	end
endmodule

//get regular and abs values of x1 - x0
module x1mx0 (
	input [8:0] i_x0,
	input [8:0] i_x1,
	output logic [8:0] o_x1mx0,
	output logic [8:0] o_abs_x1mx0
	);
	
	always_comb begin
		o_x1mx0 = i_x1 - i_x0;
		if (o_x1mx0[8] == 1'b1) begin
			o_abs_x1mx0 = -o_x1mx0;
		end
		else begin
			o_abs_x1mx0 = o_x1mx0;
		end
	end
endmodule

//comparator for steep
module comp_steep (
	input [7:0] i_abs_y1my0,
	input [8:0] i_abs_x1mx0,
	output o_steep
	);
	
	assign o_steep = i_abs_y1my0 > i_abs_x1mx0;

endmodule

//comparator for x0gtx1
module comp_x0gtx1 (
	input [8:0] i_x0,
	input [8:0] i_x1,
	output o_x0gtx1
	);
	
	assign o_x0gtx1 = i_x0 > i_x1;

endmodule

//register for storing and setting deltax deltay and ystep
module params_reg (
	input [8:0] i_x1mx0,
	input [7:0] i_abs_y1my0,
	input [7:0] i_y0,
	input [7:0] i_y1,
	input i_set_params,
	input i_clk,
	input i_reset,
	output logic [8:0] o_deltax,
	output logic [7:0] o_deltay,
	output logic o_ystep
	);
	
	always_ff @ (posedge i_clk) begin
		if (i_reset) begin
			o_deltax <= 9'b0;
			o_deltay <= 8'b0;
			o_ystep <= 1'b0;
		end
		else if (i_set_params) begin
			o_deltax <= i_x1mx0;
			o_deltay <= i_abs_y1my0;
			if (i_y0 < i_y1) begin
				o_ystep <= 1'b1;
			end
			else begin
				o_ystep <= 1'b0;
			end
		end
		else begin
			o_deltax <= o_deltax;
			o_deltay <= o_deltay;
			o_ystep <= o_ystep;
		end
	end
endmodule

//initialize and update xy for drawing
module xy (
	output logic [8:0] o_x,
	output logic [7:0] o_y,
	output logic o_xgtx0,
	input i_clk,
	input i_reset,
	input i_init,
	input i_ystep,
	input i_upd_err,
	input i_upd_xy,
	input [8:0] i_deltax,
	input [7:0] i_deltay,
	input [8:0] i_x0,
	input [7:0] i_y0,
	input steep
);
	logic [8:0] error;
	logic [8:0] x;
	logic [7:0] y;
	
	always_ff @ (posedge i_clk) begin
		if (i_reset) begin
			x <= 9'b0;
			y <= 8'b0;
			error <= 9'b0;
		end
		else if (i_init) begin
			x <= i_x0;
			y <= i_y0;
			error <= -(i_deltax/2);
		end
		else if (i_upd_err) begin
			error <= error + i_deltay;
		end
		else if (i_upd_xy) begin
			x <= x + 1;
			if (error > 9'b0) begin
				error <= error - i_deltax;
				if (i_ystep) begin
					y <= y +1;
				end
				else begin
					y <= y +1;
				end
			end
		end
		else begin 
			x <= x;
			y <= y;
			error <= error;
		end
	end
	
	always_comb begin
		o_xgtx0 = x > i_x0;
		if (steep) begin
			o_y = x;
			o_x = y;
		end
		else begin
			o_y = y;
			o_x = x;
		end
	end
endmodule

			
