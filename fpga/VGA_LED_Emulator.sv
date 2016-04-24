/*
 * Seven-segment LED emulator
 *
 * Stephen A. Edwards, Columbia University
 */

module VGA_LED_Emulator(
 input logic 	    clk108, reset,
 //input logic[9:0] ballX, ballY,
 output logic [7:0] VGA_R, VGA_G, VGA_B,
 output logic 	    VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 48,
             HSYNC        = 11'd 112,
             HBACK_PORCH  = 11'd 248,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC + HBACK_PORCH; // 1688
   
   // Parameters for vcount
   parameter VACTIVE      = 11'd 1024,
             VFRONT_PORCH = 11'd 1,
             VSYNC        = 11'd 3,
             VBACK_PORCH  = 11'd 38,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC + VBACK_PORCH; // 1066

   // Horizontal counter
	logic [10:0]		  hcount;              
   logic 			     endOfLine;
   
	// Vertical counter
   logic [10:0] 		  vcount;
   logic 			     endOfField;
	
   always_ff @(posedge clk108 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
   
   always_ff @(posedge clk108 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 11'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // original 101 0010 0000 to 101 1101 1111
	// new      101 0011 0000 to 101 1010 0000
	// should go high again on 101 1010 0001
	
	always_ff @(posedge clk108) begin 
		if (hcount >= 11'b10100110000 && hcount <= 11'b10110100000)
			VGA_HS <= 1;
		else
			VGA_HS <= 0;
		
		
		//assign VGA_HS = !( (hcount[10:8] == 3'b101) & !(hcount[7:5] == 3'b111));
		
		if (vcount >= 11'b10000000001 && vcount <= 11'b10000000100)
			VGA_VS <= 1;
		else
			VGA_VS <= 0;	
		
	  // VGA_BLANK_n turns off screen when not drawing pixels
	  if (hcount < HACTIVE && vcount < VACTIVE )
			VGA_BLANK_n <= 1;
		else 
			VGA_BLANK_n <= 0;
			
		 
	end 

	//assign VGA_VS = !( vcount[10:2] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 0; // For adding sync to video signals; not used for VGA
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
	

	/*
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );   
	*/
	
   /* VGA_CLK is 108 MHz
    *             __    __    __
    * clk108    __|  |__|  |__|
    *        
    */
   assign VGA_CLK = clk108; // 108 MHz clock: pixel latched on rising edge
	assign {VGA_R, VGA_G, VGA_B} = {8'h00, 8'hbf, 8'hff};
	
	/*
	assign inBall = ((hcount[10:1] - ballX)*(hcount[10:1] - ballX) + (vcount[9:0] - ballY)*(vcount[9:0] - ballY)) < 64;
	
   always_comb begin
      {VGA_R, VGA_G, VGA_B} = {8'h00, 8'hbf, 8'hff}; // Blue
      if (inBall)
			{VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'h00}; // Yellow			
   end  
   */
endmodule // VGA_LED_Emulator
