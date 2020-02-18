module de1soc_top 
(
    // Clock pins
    input                       CLOCK_50,

    // Seven Segment Displays
    output      [ 6: 0]         HEX0,
    output      [ 6: 0]         HEX1,
    output      [ 6: 0]         HEX2,
    output      [ 6: 0]         HEX3,
    output      [ 6: 0]         HEX4,
    output      [ 6: 0]         HEX5,

    // Pushbuttons
    input       [ 3: 0]         KEY,

    // LEDs
    output      [ 9: 0]         LEDR,

    // Slider Switches
    input       [ 9: 0]         SW,

    // VGA
    output      [ 7: 0]         VGA_B,
    output                      VGA_BLANK_N,
    output                      VGA_CLK,
    output      [ 7: 0]         VGA_G,
    output                      VGA_HS,
    output      [ 7: 0]         VGA_R,
    output                      VGA_SYNC_N,
    output                      VGA_VS
);

	// CPU Signals
	logic [15:0] cpu_mem_addr;
	logic        cpu_mem_rd;
	logic        cpu_mem_wr;
	logic [15:0] cpu_mem_rddata;
	logic [15:0] cpu_mem_wrdata;
    // mem4k Signals
	logic [15:0] mem4k_addr;
	logic [15:0] mem4k_wrdata;
	logic        mem4k_wr;
	logic		 mem4k_rd;
	logic [15:0] mem4k_rddata;
	// LEDR Signals
	logic        ledr_en;
	logic  [7:0] ledr_data_in;
	logic  [7:0] ledr_data_out;
	// SW Signals
	logic [7:0] sw_data_out;
	
	assign LEDR [7:0] = ledr_data_out;
	
	cpu cpu1 (
		.i_clk			(CLOCK_50),
		.i_reset		(KEY[0]),

		.o_mem_addr     (cpu_mem_addr),
		.o_mem_rd       (cpu_mem_rd),
		.o_mem_wr       (cpu_mem_wr),
		.i_mem_rddata   (cpu_mem_rddata),
		.o_mem_wrdata   (cpu_mem_wrdata)
	);

	mem4k memory (
		.clk            (CLOCK_50),

		.addr           (mem4k_addr),		// 2048 words means 11 bits of address
		.wrdata         (mem4k_wrdata),	// Each word is 16 bits wide
		.wr             (mem4k_wr),
		.rd				(cpu_mem_rd),
		.rddata 		(mem4k_rddata)
	);
	
	reg_var #(
		.WIDTH          (8)
	) ledr_reg (
		.i_clk			(CLOCK_50),
		.i_reset		(KEY[0]),

		.i_en           (ledr_en),
		.i_data_in      (ledr_data_in),
		.o_data_out     (ledr_data_out)
	);
	
	reg_var #(
		.WIDTH          (8)
	) sw_reg (
		.i_clk			(CLOCK_50),
		.i_reset		(KEY[0]),

		.i_en           (1'b1),
		.i_data_in      (SW[7:0]),
		.o_data_out     (sw_data_out)
	);
	
	mem_logic bus (
		// cpu interface
		.i_cpu_mem_addr(cpu_mem_addr),
		.i_cpu_mem_wr(cpu_mem_wr),
		.i_cpu_mem_wrdata(cpu_mem_wrdata),
		.o_cpu_mem_rddata(cpu_mem_rddata),

		// memory interface
		.i_mem4k_rddata(mem4k_rddata),
		.o_mem4k_addr(mem4k_addr),
		.o_mem4k_wr(mem4k_wr),
		.o_mem4k_wrdata(mem4k_wrdata),
		
		//ledr interface
		.o_ledr_en(ledr_en),
		.o_ledr_data(ledr_data_in),
		.i_ledr_data(ledr_data_out),
		
		//switch interface
		.i_sw_data(sw_data_out)	
	);


endmodule
