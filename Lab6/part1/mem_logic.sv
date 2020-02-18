module mem_logic (
	// cpu interface
	input[15:0] i_cpu_mem_addr,
	input i_cpu_mem_wr,
	input[15:0] i_cpu_mem_wrdata,
	output logic [15:0] o_cpu_mem_rddata,

	// memory interface
	input[15:0] i_mem4k_rddata,
	output logic [15:0] o_mem4k_addr,
	output logic o_mem4k_wr,
	output logic [15:0] o_mem4k_wrdata,
	
	//ledr interface
	output logic o_ledr_en,
	output logic [7:0] o_ledr_data,
	input [7:0] i_ledr_data,
	
	//switch interface
	input [7:0] i_sw_data	
);

	always_comb begin
		//defaults
		o_cpu_mem_rddata = {'0};
		o_mem4k_addr = i_cpu_mem_addr >> 1;
		o_mem4k_wr = {'0};
		o_mem4k_wrdata = i_cpu_mem_wrdata;
		o_ledr_en = {'0};
		o_ledr_data = i_cpu_mem_wrdata[7:0];
		
		case (i_cpu_mem_addr[15:12])
		
			2: begin // sw
				o_cpu_mem_rddata = {8'd0,i_sw_data};
			end

			3: begin // ledr
				o_ledr_en  = i_cpu_mem_wr;
				o_cpu_mem_rddata = {8'd0,i_ledr_data};
			end

			default: begin  // mem4k
				o_mem4k_wr = i_cpu_mem_wr;
				o_cpu_mem_rddata = i_mem4k_rddata;
			end
		endcase
	end
endmodule