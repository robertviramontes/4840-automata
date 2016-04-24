/* jco2127 jat2164 */

/*
 * Avalon memory-mapped peripheral for the VGA LED Emulator
 *
 * Stephen A. Edwards
 * Columbia University
 */

module VGA_LED(input logic        clk, clkmem,
	       input logic 	  reset,
	       input logic [31:0]  writedata,
	       input logic 	  write,
			 output logic read1, 
	       input 		  chipselect,
	       input logic [2:0]  address,
			 input logic [19:0] q_b_1, 
			 
			 output logic [15:0] address_b_1, 
	       output logic [7:0] VGA_R, VGA_G, VGA_B,
	       output logic 	  VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	       output logic 	  VGA_SYNC_n);

   //VGA_LED_Emulator led_emulator(.clk108(clk), .reset(reset), .*);
	VGA_LED_Emulator led_emulator (.clk108(clk), .reset(reset), .VGA_R(VGA_R), 
											.VGA_G(VGA_G), .VGA_B(VGA_B),
											.VGA_CLK(VGA_CLK), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), 
											.VGA_BLANK_n(VGA_BLANK_n), .VGA_SYNC_n(VGA_SYNC_n));

	/*
   always_ff @(posedge clk)
		if (reset) begin
			ballX <= 10'd320;
			ballY <= 10'd240;
		end else if (chipselect && write) begin
			ballX <= writedata[9:0];
			ballY <= writedata[25:16];
		end
*/
		endmodule
