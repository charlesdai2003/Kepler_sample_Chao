module lda_control (
	output logic o_set_steep,
	output logic o_set_x0gtx1,
	output logic o_set_params,
	output logic o_set_x0x1y0y1,
	output logic o_init,
	output logic o_upd_err,
	output logic o_upd_xy,
	output logic o_plot,
	output logic o_done,
	output logic o_reset,
	input i_xgtx0,
	input i_start,
	input i_clk,
	input i_reset
	);
	
	//States
	enum int unsigned {
		WAIT, //initial state reset registers
		SET_X0X1Y0Y1, //load initial x0 x1 y0 y1 into registers
		SET_STEEP, //compare for steep and manipulate x0 x1 y0 y1 to reflect this
		SET_X0GTX1, //see of x0 > x1 and manipulate x0 x1 y0 y1 to reflect this
		SET_PARAMS, //set ystep deltax deltay
		INT_DRAW, //set initial x y and error
		DRAW, //draw
		UPD_ERR, //update error
		UPD_XY, //update x error y if needed
		DONE //finished drawing
	} state, nextstate;
	
	//Reset and state registers
	always_ff @ (posedge i_clk or posedge i_reset) begin
		if (i_reset) state <= WAIT;
		else state <= nextstate;
	end
	
	always_comb begin
	//default values
	nextstate = state;
	o_set_steep = 1'b0;
	o_set_x0gtx1 = 1'b0;
	o_set_params = 1'b0;
	o_set_x0x1y0y1 = 1'b0;
	o_init = 1'b0;
	o_upd_err = 1'b0;
	o_upd_xy = 1'b0;
	o_plot = 1'b0;
	o_done = 1'b0;
	o_reset = 1'b0;
	
	//state table
		case(state)
			WAIT: begin
				o_reset = 1'b1;
				if (i_start) nextstate = SET_X0X1Y0Y1;
			end
			SET_X0X1Y0Y1: begin
				o_set_x0x1y0y1 = 1'b1;
				nextstate = SET_STEEP;
			end
			SET_STEEP: begin
				o_set_steep = 1'b1;
				nextstate = SET_X0GTX1;
			end
			SET_X0GTX1: begin
				o_set_x0gtx1 = 1'b1;
				nextstate = SET_PARAMS;
			end
			SET_PARAMS: begin
				o_set_params = 1'b1;
				nextstate = INT_DRAW;
			end
			INT_DRAW: begin
				o_init = 1'b1;
				nextstate = DRAW;
			end
			DRAW: begin
				o_plot = 1'b1;
				nextstate = UPD_ERR;
			end
			UPD_ERR: begin
				o_upd_err = 1'b1;
				nextstate = UPD_XY;
			end
			UPD_XY: begin
				o_upd_xy = 1'b1;
				if (i_xgtx0) nextstate = DONE;
				else nextstate = DRAW;
			end
			DONE: begin
				o_done = 1'b1;
				nextstate = WAIT;
			end
		endcase
	end
endmodule	
	
	
	
	
	
	
	
	
	
	
	