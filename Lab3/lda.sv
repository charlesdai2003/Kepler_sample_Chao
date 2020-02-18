module lda (
	input [8:0] i_x0,
	input [8:0] i_x1,
	input [7:0] i_y0,
	input [7:0] i_y1,
	input [2:0] i_colour,
	input logic i_reset,
	input logic i_clk,
	input logic i_start,
	output logic o_done,
	output logic o_plot,
	output logic [8:0] o_x,
	output logic [7:0] o_y,
	output logic o_colour
	);

	assign o_colour = i_colour;
	
	logic set_steep;
	logic set_x0gtx1;
	logic set_params;
	logic set_x0x1y0y1;
	logic init;
	logic upd_err;
	logic upd_xy;
	logic xgtx0;
	logic dp_reset;
	
	lda_data datapath (
	.i_x0(i_x0),
	.i_y0(i_y0),
	.i_x1(i_x1),
	.i_y1(i_y1),
	.i_clk(i_clk),
	.i_reset(dp_reset),
	.i_set_steep(set_steep),
	.i_set_x0gtx1(set_x0gtx1),
	.i_set_params(set_params),
	.i_set_x0x1y0y1(set_x0x1y0y1),
	.i_init(init),
	.i_upd_err(upd_err),
	.i_upd_xy(upd_xy),
	.o_xgtx0(xgtx0),
	.o_x(o_x),
	.o_y(o_y)
	);
	
	lda_control controlpath (
	.o_set_steep(set_steep),
	.o_set_x0gtx1(set_x0gtx1),
	.o_set_params(set_params),
	.o_set_x0x1y0y1(set_x0x1y0y1),
	.o_init(init),
	.o_upd_err(upd_err),
	.o_upd_xy(upd_xy),
	.o_plot(o_plot),
	.o_done(o_done),
	.o_reset(dp_reset),
	.i_xgtx0(xgtx0),
	.i_start(i_start),
	.i_clk(i_clk),
	.i_reset(i_reset)
	);
endmodule