module cpu_controlpath (
	input i_reset,
	input i_clk,
	input i_n,
	input i_z,
	output logic [2:0] o_x,
	output logic [2:0] o_y,
	output logic o_write_y,
	output logic o_write_alu,
	output logic o_write_mem,
	output logic o_mem_sel,
	output logic o_alu_sel,
	output logic o_write_pc,
	output logic o_incr_pc,
	output logic o_write_imm,
	output logic o_set_pc_rx,
	output logic o_set_pc_imm,
	output logic o_set_nz,
	output logic o_op_sel,
	output logic o_write_high,
	output logic [7:0] o_nse_imm8,
	output logic [15:0] o_imm8,
	output logic [15:0] o_imm11,
	
	
	//to memory module
	output logic o_mem_rd,
	output logic o_mem_wr,
	input [15:0] i_mem_rdata
);
	//comb logic outputs
	assign o_nse_imm8 = i_mem_rdata[15:8];
	assign o_imm8 = {{8{i_mem_rdata[15]}},i_mem_rdata[15:8]};
	assign o_imm11 = {{5{i_mem_rdata[15]}},i_mem_rdata[15:5]};
	assign o_x = i_mem_rdata[7:5];
	assign o_y = i_mem_rdata[10:8];
	
	// States
	enum int unsigned
	{
	  S_FETCH,
	  S_PREPARE_EXE,
	  S_EXECUTE,
	  S_MEM_LD
	} state, nextstate;

	// State regs
	always_ff @ (posedge i_clk or posedge i_reset) begin
	   if (i_reset) state <= S_FETCH;
	   else state <= nextstate;
	end
	
	//State table
	always_comb begin
		nextstate = state;
		o_write_y = 1'b0;
		o_write_alu = 1'b0;
		o_write_mem = 1'b0;
		o_mem_sel = 1'b1;
		o_alu_sel = 1'b0;
		o_write_pc = 1'b0;
		o_incr_pc = 1'b0;
		o_set_pc_rx = 1'b0;
		o_set_pc_imm = 1'b0;
		o_set_nz = 1'b0;
		o_op_sel = 1'b0;
		o_write_imm = 1'b0;
		o_write_high = 1'b0;
		o_mem_rd = 1'b0;
		o_mem_wr = 1'b0;
		
		case (state)
			
			S_FETCH: begin
				nextstate = S_PREPARE_EXE;
				o_mem_rd = 1'b1; 
				o_mem_sel = 1'b1;
			end
			
			S_PREPARE_EXE: begin
				o_incr_pc = 1'b1;
				
				case (i_mem_rdata[3:0])
				
					//mv mvi
					4'b0000: begin
						nextstate = S_FETCH;
						if (i_mem_rdata[4]) o_write_imm = 1'b1;
						else o_write_y = 1'b1;
					end
					
					//add addi
					4'b0001: begin
						nextstate = S_EXECUTE;
						o_op_sel = 1'b0;
						if (i_mem_rdata[4]) o_alu_sel = 1'b1;
						else o_alu_sel = 1'b1;
					end
					
					//sub subi
					4'b0010: begin
						nextstate = S_EXECUTE;
						o_op_sel = 1'b1;
						if (i_mem_rdata[4]) o_alu_sel = 1'b1;
						else o_alu_sel = 1'b1;
					end
					
					//cmp cmpi
					4'b0011: begin
						nextstate = S_EXECUTE;
						o_op_sel = 1'b1;
						if (i_mem_rdata[4]) o_alu_sel = 1'b1;
						else o_alu_sel = 1'b1;
					end
					
					//ld
					4'b0100: begin
						nextstate = S_MEM_LD;
						o_mem_sel = 1'b0;
						o_mem_rd = 1'b1;
					end
					
					//st
					4'b0101: begin
						nextstate = S_EXECUTE;
						o_mem_sel = 1'b0;
					end
					
					//mvhi
					4'b0110: begin
						nextstate = S_FETCH;
						o_write_high = 1'b1;
					end
					
					//jr j
					4'b1000: begin
						nextstate = S_EXECUTE;
					end
					
					//jz jzr
					4'b1001: begin
						if (i_z) nextstate = S_EXECUTE;
						else nextstate = S_FETCH;
					end
					
					//jn jnr
					4'b1010: begin
						if (i_n) nextstate = S_EXECUTE;
						else nextstate = S_FETCH;
					end
					
					//call callr
					4'b1100: begin
						o_write_pc = 1'b1;
						nextstate = S_EXECUTE;
					end
					
					default: begin
						nextstate = S_FETCH;
					end
					
				endcase
			end
			
			S_EXECUTE: begin
			
				case (i_mem_rdata[3:0])
			
					//add addi
					4'b0001: begin
						nextstate = S_FETCH;
						o_op_sel = 1'b0;
						if (i_mem_rdata[4]) o_alu_sel = 1'b1;
						else o_alu_sel = 1'b1;
						o_set_nz = 1'b1;
						o_write_alu = 1'b1;
						
					end
					
					//sub subi
					4'b0010: begin
						nextstate = S_FETCH;
						o_op_sel = 1'b1;
						if (i_mem_rdata[4]) o_alu_sel = 1'b1;
						else o_alu_sel = 1'b1;
						o_set_nz = 1'b1;
						o_write_alu = 1'b1;
					end
					
					//cmp cmpi
					4'b0011: begin
						nextstate = S_FETCH;
						o_op_sel = 1'b1;
						if (i_mem_rdata[4]) o_alu_sel = 1'b1;
						else o_alu_sel = 1'b1;
						o_set_nz = 1'b1;
					end
					
					//st
					4'b0101: begin
						nextstate = S_FETCH;
						o_mem_sel = 1'b0;
						o_mem_wr = 1'b1;
						
					end
					
					//jr j
					4'b1000: begin
						nextstate = S_FETCH;
						if (i_mem_rdata[4]) o_set_pc_imm = 1'b1;
						else o_set_pc_rx = 1'b1;
					end
					
					//jz jzr
					4'b1001: begin
						nextstate = S_FETCH;
						if (i_mem_rdata[4]) o_set_pc_imm = 1'b1;
						else o_set_pc_rx = 1'b1;
					end
					
					//jn jnr
					4'b1010: begin
						nextstate = S_FETCH;
						if (i_mem_rdata[4]) o_set_pc_imm = 1'b1;
						else o_set_pc_rx = 1'b1;
					end
					
					//call callr
					4'b1100: begin
						if (i_mem_rdata[4]) o_set_pc_imm = 1'b1;
						else o_set_pc_rx = 1'b1;
						nextstate = S_FETCH;
					end
					
					default: begin
						nextstate = S_FETCH;
					end
					
				endcase
			end
			
			S_MEM_LD: begin
				nextstate = S_FETCH;
				o_mem_sel = 1'b0;
				o_mem_rd = 1'b1;
				o_write_mem = 1'b1;
			end
		endcase
	end
endmodule