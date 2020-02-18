module cpu_datapath (
	input i_reset,
	input i_clk,
	input [2:0] i_x,
	input [2:0] i_y,
	input [15:0] i_mem_rdata,
	input i_write_y,
	input i_write_alu,
	input i_write_mem,
	input i_mem_sel,
	input i_alu_sel,
	input i_write_pc,
	input i_incr_pc,
	input i_set_pc_rx,
	input i_set_pc_imm,
	input i_write_imm,
	input i_set_nz,
	input i_op_sel,
	input i_write_high,
	input [7:0] i_nse_imm8,
	input [15:0] i_imm8,
	input [15:0] i_imm11,
	output logic o_n,
	output logic o_z,
	output logic [15:0] o_mem_addr,
	output logic [15:0] x_data
);
	logic [15:0] y_data;
	logic [15:0] alu_out;
	logic [15:0] pc;
	logic [15:0] alu_op_b;
	logic n;
	logic z;
	
	regs #(
		.WIDTH (16),
		.NUMBER_REG (8)
	) registers (
		.i_reset(i_reset),
		.i_clk(i_clk),
		.i_x(i_x),
		.i_y(i_y),
		.i_alu(alu_out),
		.i_pc(pc),
		.i_write_pc(i_write_pc),
		.i_mem_rdata(i_mem_rdata),
		.i_nse_imm8(i_nse_imm8),
		.i_write_y(i_write_y),
		.i_write_imm(i_write_imm),
		.i_imm8(i_imm8),
		.i_write_alu(i_write_alu),
		.i_write_mem(i_write_mem),
		.i_write_high(i_write_high),
		.o_x(x_data),
		.o_y(y_data)
	);
	
	mem_mux #(
		.WIDTH (16)
	) mux_reg (
		.i_pc(pc),
		.i_y(y_data),
		.i_mem_sel(i_mem_sel),
		.o_mem_addr(o_mem_addr)
	);

	alu_mux #(
		.WIDTH (16)
	) mux_alu (
		.i_ry(y_data),
		.i_imm8(i_imm8),
		.i_alu_sel(i_alu_sel),
		.o_op_b(alu_op_b)
	);
	
	pc_reg #(
		.WIDTH (16)
	) reg_pc (
		.i_reset(i_reset),
		.i_incr_pc(i_incr_pc),
		.i_set_pc_rx(i_set_pc_rx),
		.i_set_pc_imm(i_set_pc_imm),
		.i_clk(i_clk),
		.i_set_value_rx(x_data),
		.i_set_value_imm(i_imm11),
		.o_pc(pc)
	);
	
	nz_reg reg_nz (
		.i_n(n),
		.i_z(z),
		.i_reset(i_reset),
		.i_set_nz(i_set_nz),
		.i_clk(i_clk),
		.o_n(o_n),
		.o_z(o_z)
	);
	
	alu #(
		.WIDTH (16)
	) alu_1 (
		.i_op_sel(i_op_sel),
		.i_op_a(x_data),
		.i_op_b(alu_op_b),
		.o_alu_out(alu_out),
		.o_n(n),
		.o_z(z)
	);
endmodule

module regs # (
	parameter WIDTH = 2,
	parameter NUMBER_REG = 2
)
(
	input i_reset,
	input i_clk,
	input [$clog2(NUMBER_REG)-1:0] i_x,
	input [$clog2(NUMBER_REG)-1:0] i_y,
	input [WIDTH-1:0] i_alu,
	input [WIDTH-1:0] i_mem_rdata,
	input [7:0] i_nse_imm8,
	input [15:0] i_imm8,
	input [WIDTH-1:0] i_pc,
	input i_write_pc,
	input i_write_y,
	input i_write_imm,
	input i_write_alu,
	input i_write_mem,
	input i_write_high,
	output logic [WIDTH-1:0] o_x,
	output logic [WIDTH-1:0] o_y
);

	logic [NUMBER_REG-1:0] [WIDTH-1:0] regs;
	logic [7:0] regs_low;
	assign regs_low = regs[i_x];
	assign o_x = regs[i_x];
	assign o_y = regs[i_y];
	
	always_ff @ (posedge i_clk, posedge i_reset) begin
		if (i_reset) regs <= {'0};
		else if (i_write_y) regs[i_x] <= regs[i_y];
		else if (i_write_imm) regs[i_x] <= i_imm8;
		else if (i_write_alu) regs[i_x] <= i_alu;
		else if (i_write_mem) regs[i_x] <= i_mem_rdata;
		else if (i_write_high) regs [i_x] <= {i_nse_imm8, regs_low};
		else if (i_write_pc) regs [7] <= i_pc+2;
		else regs <= regs;
	end
endmodule

//0 = ry and 1 = pc
module mem_mux # (
 parameter WIDTH = 2
)
(
	input [WIDTH-1:0] i_pc,
	input [WIDTH-1:0] i_y,
	input i_mem_sel,
	output logic [WIDTH-1:0] o_mem_addr
);
	always_comb begin
		if (i_mem_sel) o_mem_addr = i_pc;
		else o_mem_addr = i_y;
	end
endmodule

//0 = ry and 1 = imm8
module alu_mux # (
 parameter WIDTH = 2
)
(
	input [WIDTH-1:0] i_ry,
	input [WIDTH-1:0] i_imm8,
	input i_alu_sel,
	output logic [WIDTH-1:0] o_op_b
);
	always_comb begin
		if (i_alu_sel) o_op_b = i_imm8;
		else o_op_b = i_ry;
	end
endmodule

module pc_reg # (
 parameter WIDTH = 2
)
(
	input i_reset,
	input i_incr_pc,
	input i_set_pc_rx,
	input i_set_pc_imm,
	input i_clk,
	input [WIDTH-1:0] i_set_value_rx,
	input [WIDTH-1:0] i_set_value_imm,
	output logic [WIDTH-1:0] o_pc
);
	always_ff @ (posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			o_pc <= {'0};
		end
		else if (i_set_pc_rx) begin
			o_pc <= i_set_value_rx;
		end
		else if (i_set_pc_imm) begin
			o_pc <= o_pc + 2*i_set_value_imm;
		end
		else if (i_incr_pc) begin
			o_pc <= o_pc+2;
		end
		else begin
			o_pc <= o_pc;
		end
	end
endmodule

module nz_reg (
	input i_n,
	input i_z,
	input i_reset,
	input i_set_nz,
	input i_clk,
	output logic o_n,
	output logic o_z
);
	always_ff @ (posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			o_n <= 1'b0;
			o_z <= 1'b0;
		end
		else if (i_set_nz) begin
			o_n <= i_n;
			o_z <= i_z;
		end
		else begin
			o_n <= o_n;
			o_z <= o_z;
		end
	end
endmodule

module alu #
(
  parameter WIDTH = 2
)
(
  input i_op_sel,
  input [WIDTH-1:0] i_op_a,
  input [WIDTH-1:0] i_op_b,
  output logic [WIDTH-1:0] o_alu_out,
  output logic o_n,
  output logic o_z
);

  // negative and zero flags
  assign o_n = o_alu_out[WIDTH-1];
  assign o_z = ~|o_alu_out;

  // combinational computation
  always_comb begin
    case (i_op_sel)
      0: o_alu_out = i_op_a + i_op_b;
      1: o_alu_out = i_op_a - i_op_b;
      default: o_alu_out = {'0};
    endcase
  end

endmodule