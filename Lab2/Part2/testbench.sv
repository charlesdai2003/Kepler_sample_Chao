`timescale 1ns/1ns

module testbench();

	// Clock Signal
	logic clk;
	initial clk = 1'b0;
	always #10 clk = ~clk;
	
	
	// DUT Signals
	logic [7:0] dut_m;
	logic [7:0] dut_q;
	logic [16:0] dut_p;
	
	// DUT Instantiation
	us_csm_var #(
		.SIZE(8)
	) DUT (
		.i_m(dut_m),
		.i_q(dut_q),
		.o_p(dut_p)
	);
	
	//Start testbench
	initial begin
		
		@(posedge clk);
		
			for (integer m = 0; m < 2**8; m++) begin
				for (integer q = 0; q < 2**8; q++) begin
					logic [15:0] prod;
					prod = m * q;
					
					dut_m = m[7:0];
					dut_q = q[7:0];
					
					@(posedge clk);
					@(posedge clk);
					
					if (dut_p !== prod) begin
						$display("Unexpected Output of DUT!");
						$display("Expected Output: %0d * %0d = %0d", m, q, prod);
						$display("DUT Output: %0d",dut_p);
						$stop;
					end
				end
			end
			$display("Done!");
			$stop;
			
	end
	
endmodule	