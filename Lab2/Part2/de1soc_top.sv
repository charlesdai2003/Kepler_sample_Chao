module de1soc_top 
(
	// These are the board inputs/outputs required for all the ECE342 labs.
	// Each lab can use the subset it needs -- unused pins will be ignored.
	
    // Clock pins
    input                     CLOCK_50,

    // Seven Segment Displays
    output      [6:0]         HEX0,
    output      [6:0]         HEX1,
    output      [6:0]         HEX2,
    output      [6:0]         HEX3,
    output      [6:0]         HEX4,
    output      [6:0]         HEX5,

    // Pushbuttons
    input       [3:0]         KEY,

    // LEDs
    output      [9:0]         LEDR,

    // Slider Switches
    input       [9:0]         SW,

    // VGA
    output      [7:0]         VGA_B,
    output                    VGA_BLANK_N,
    output                    VGA_CLK,
    output      [7:0]         VGA_G,
    output                    VGA_HS,
    output      [7:0]         VGA_R,
    output                    VGA_SYNC_N,
    output                    VGA_VS
);
	
	// Design goes here
	logic dp_en;
	logic [7:0] x_out;
	logic [7:0] y_out;
	logic [15:0] reg_out;
	logic [15:0] prod;
	
	assign dp_en = SW[9];
	
	reg_var # (
		SIZE=8
	) reg_x (
		.i_clk(CLOCK_50),
		.i_en(dp_en),
		.i_in(SW[7:0]),
		.o_out (x_out)
	);
	
	reg_var # (
		SIZE=8
	) reg_y (
		.i_clk(CLOCK_50),
		.i_en(~dp_en),
		.i_in(SW[7:0]),
		.o_out (y_out)
	);
	
	us_csm_var #
	(
		SIZE = 8
	) csm (
		.i_m(x_out),
		.i_q(y_out),
		.o_p(prod)
	)
	
	reg_var # (
		SIZE=16
	) out (
		.i_clk(CLOCK_50),
		.i_en(1'b1),
		.i_in(prod),
		.o_out (reg_out)
	);
	
	hex_decoder m_hex0 (
    .hex_digit(reg_out[3:0]),
    .segments(HEX0)
	);

	hex_decoder m_hex1 (
		.hex_digit(reg_out[7:4]),
		.segments(HEX1)
	);

	hex_decoder m_hex2 (
		.hex_digit(reg_out[11:8]),
		.segments(HEX2)
	);

	hex_decoder m_hex3 (
		.hex_digit(reg_out[15:12]),
		.segments(HEX3)
	);
	
endmodule