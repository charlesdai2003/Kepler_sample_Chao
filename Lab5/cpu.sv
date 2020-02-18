module cpu (
	input clk,
	input reset,

	// memory bus interface
	output [15:0] o_mem_addr,
	output o_mem_rd,
	output o_mem_wr,
	input  [15:0] i_mem_rddata,
	output [15:0] o_mem_wrdata
);

	//logic
	logic n;
	logic z;
	logic [2:0] x;
	logic [2:0] y;
	logic write_y;
	logic write_alu;
	logic write_mem;
	logic mem_sel;
	logic alu_sel;
	logic write_pc;
	logic incr_pc;
	logic write_imm;
	logic set_pc_rx;
	logic set_pc_imm;
	logic set_nz;
	logic op_sel;
	logic write_high;
	logic [7:0] nse_imm8;
	logic [15:0] imm8;
	logic [15:0] imm11;
	
	cpu_controlpath controlpath(
		.i_reset(reset),
		.i_clk(clk),
		.i_n(n),
		.i_z(z),
		.o_x(x),
		.o_y(y),
		.o_write_y(write_y),
		.o_write_alu(write_alu),
		.o_write_mem(write_mem),
		.o_mem_sel(mem_sel),
		.o_alu_sel(alu_sel),
		.o_write_pc(write_pc),
		.o_incr_pc(incr_pc),
		.o_write_imm(write_imm),
		.o_set_pc_rx(set_pc_rx),
		.o_set_pc_imm(set_pc_imm),
		.o_set_nz(set_nz),
		.o_op_sel(op_sel),
		.o_write_high(write_high),
		.o_nse_imm8(nse_imm8),
		.o_imm8(imm8),
		.o_imm11(imm11),
		.o_mem_rd(o_mem_rd),
		.o_mem_wr(o_mem_wr),
		.i_mem_rdata(i_mem_rddata)
	);
	
	cpu_datapath datapath(
		.i_reset(reset),
		.i_clk(clk),
		.i_x(x),
		.i_y(y),
		.i_mem_rdata(i_mem_rddata),
		.i_write_y(write_y),
		.i_write_alu(write_alu),
		.i_write_mem(write_mem),
		.i_mem_sel(mem_sel),
		.i_alu_sel(alu_sel),
		.i_write_pc(write_pc),
		.i_incr_pc(incr_pc),
		.i_set_pc_rx(set_pc_rx),
		.i_set_pc_imm(set_pc_imm),
		.i_write_imm(write_imm),
		.i_set_nz(set_nz),
		.i_op_sel(op_sel),
		.i_write_high(write_high),
		.i_nse_imm8(nse_imm8),
		.i_imm8(imm8),
		.i_imm11(imm11),
		.o_n(n),
		.o_z(z),
		.o_mem_addr(o_mem_addr),
		.x_data(o_mem_wrdata)
	);
	
endmodule