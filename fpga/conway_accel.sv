// Management surrounding the Conway accelerator including buffers
module Conway_Accel(
 // need end-of-screen logic from the VGA controller
 
 input clk, reset,
 // VGA controller will access memory exclusively on B ports, through this module.
 // TODO: VGA should only ask for one address/data, accelerator determines which 
 //       memory it is coming from
 
 input  [15:0] address_b_1, 
 output [19:0] q_b_1
 
);

  // for memories, data_b should be unused (never writing through the data ports)
  // clocks can *probably* be the same? implement buffering in the VGA controller?
  // 
  
  logic [15:0] address_a_1, address_a_2;
  logic [19:0] data_b, q_a_1, q_a_2;
  logic [0:0] wren_a_1, wren_a_2, wren_b;
  
  assign data_b = 20'd0;
  assign wren_b = 1'd0; // never write over B port
  
  tmemory m1( 
					.address_a(address_a_1),
					.address_b(address_b_1),
					.data_a(result),
					.data_b(data_b),
					.q_a(q_a_1),
					.q_b(q_b_1),
					.wren_a(wren_a_1),
					.wren_b(wren_b),
					.clock_a(clk), .clock_b(clk)
					);
	/*
	input	[15:0]  address_a;
	input	[15:0]  address_b;
	input	  clock_a;
	input	  clock_b;
	input	[19:0]  data_a;
	input	[19:0]  data_b;
	input	  wren_a;
	input	  wren_b;
	output	[19:0]  q_a;
	output	[19:0]  q_b;
   */

  tmemory m2 (  
					.address_a(address_a_2),
					.address_b(address_b_2),
					.data_a(result),
					.data_b(data_b),
					.q_a(q_a_2),	
					.q_b(q_b_2),					
					.wren_a(wren_a_1),
					.wren_b(wren_b),
					.clock_a(clk), .clock_b(clk)
					);
					
  // TODO: this needs to be somewhere in an alwaysff or else it won't change					
  logic direction = 0; //when 0, m1 is t, when 1, m2 is t

  
  // reads from memory will go into here. 
  // necessary so that the shift registers are able to read from
  // both m1 and m2 (can't directly wire them up to different memories
  // so the different memories will go here first.)
  logic [19:0] memory_buffer; 
  logic oob;
  
  // wires connecting shift output to conway input
  wire [21:0] top_out;
  wire [21:0] middle_out;
  wire [21:0] bottom_out;
  
  // control logic for the shift registers
  logic shift_enable_t, shift_enable_m, shift_enable_b, clear;

  // instantiate shift register  
  shift_buffer top    (.din(memory_buffer), .dout(top_out),    .shift_enable(shift_enable_t), .clear(clear));
  shift_buffer middle (.din(memory_buffer), .dout(middle_out), .shift_enable(shift_enable_m), .clear(clear));
  shift_buffer bottom (.din(memory_buffer), .dout(bottom_out), .shift_enable(shift_enable_b), .clear(clear));


// instatiate conway module, wire together.

wire [19:0] result;

  Conway_Multiple cm (.top_row(top_out), 
							 .middle_row(middle_out),
							 .bottom_row(bottom_out),
							 .result(result),
							 .clk(clk));							 
				 

reg [1:0] state;
logic [0:0] frame_complete;
reg [5:0] word_count;
parameter TOP = 2'd0, MID=2'd1, BOT=2'd2, EOR=2'd3;

always_ff @(posedge clk or posedge reset) begin

	if (reset) begin
	  address_a_1 <= 16'd0;
	  address_a_2 <= 16'd0;
	  shift_enable_b <= 1'd0;
	  shift_enable_m <= 1'd0;
	  shift_enable_t <= 1'd0;
	  clear <= 1;
	  word_count <= 6'd0;
	  state <= TOP;
	  oob <= 1;
	  end
	  
	else if (frame_complete) begin
	  address_a_1 <= 16'd0;
	  address_a_2 <= 16'd0;
	  shift_enable_b <= 1'd0;
	  shift_enable_m <= 1'd0;
	  shift_enable_t <= 1'd0;
	  clear <= 1;
	  word_count <= 6'd0;
	  state <= TOP;
	  oob <= 1;
	  end
	  
	else if (direction == 0) begin
	clear <= 0;
	  case (state)
		 TOP : begin
				 if (address_a_1 < 16'd64 && oob == 1) 
					memory_buffer <= 20'd0; // dead cell buffer at top 
				 else begin
			      memory_buffer <= q_a_1;	 
				   address_a_1 <= address_a_1 + 16'd64; //address for MID
				 end
				 if (address_a_1 > 16'd65407) // in the second-to-last row
				   oob <= 1; 
         wren_a_2 <= 0; // new write address not available. don't mess with previous result when top shifted 
				 shift_enable_m <= 0;
				 shift_enable_b <= 0;
				 shift_enable_t <= 1;
				 state <= MID;
				 end

		 MID : begin
				 memory_buffer <= q_a_1; 
				 shift_enable_t <= 0;
				 shift_enable_m <= 1;
             address_a_2 <= address_a_1;  // will write to the MID address in t+1 grid
			    address_a_1 <= address_a_1 + 16'd64; // address for BOT
         if (word_count != 6'd0)
           wren_a_2 <= 1; // if looking at first word, EOR zeros still in accelerator, invalid output. 
         state <= BOT;
				 end

		 BOT : begin
				 shift_enable_m <= 0;
				 shift_enable_b <= 1;
				 if (oob == 1 && address_a_1 < 16'd128) begin
					address_a_1 = address_a_1 - 16'd64 + 16'd1; // address for TOP; go back one row, move forward one word 
					memory_buffer <= q_a_1;
				 end
				 else if (oob == 1 && address_a_1 > 16'd65471) begin
					address_a_1 <= address_a_1 - 16'd128 + 16'd1; // address for TOP; go back two rows, move forward one word 
					memory_buffer <= 22'd0; // dead cell outline at bottom
				 end
				 else begin 
				   address_a_1 <= address_a_1 - 16'd128 + 16'd1; // address for TOP; go back two rows, move forward one word 
				   memory_buffer <= q_a_1;
				 end
				 word_count <= word_count + 6'd1;
				 if(word_count == 6'd63) // at end of row
				   state <= EOR;
				 else
				   state <= TOP;
				 end

		EOR : begin
				if (oob == 1 && address_a_1 < 16'd65)
				  oob <= 0;
				else if (oob == 1) begin
					frame_complete <= 1;
					direction <= 1;
				end
				memory_buffer <= 22'd0; // when to deassert write enable so this isn't the next thing written?
				shift_enable_b <= 1;
				shift_enable_m <= 1;
				shift_enable_t <= 1;
				word_count <= 6'd0; 
				state <= TOP;
				end
			   
	  endcase
	  
	end
	
	else if (direction == 1) begin
	clear <= 0;
	  case (state)
		 TOP : begin
				 if (address_a_2 < 16'd64 && oob == 1) 
					memory_buffer <= 20'd0; // dead cell buffer at top 
				 else begin
			      memory_buffer <= q_a_2;	 
				   address_a_2 <= address_a_2 + 16'd64; //address for MID
				 end
				 if (address_a_2 > 16'd65407) // in the second-to-last row
				   oob <= 1; 
         wren_a_2 <= 0; // new write address not available. don't mess with previous result when top shifted 
				 shift_enable_m <= 0;
				 shift_enable_b <= 0;
				 shift_enable_t <= 1;
				 state <= MID;
				 end

		 MID : begin
				 memory_buffer <= q_a_2; 
				 shift_enable_t <= 0;
				 shift_enable_m <= 1;
             address_a_1 <= address_a_2;  // will write to the MID address in t+1 grid
			    address_a_2 <= address_a_2 + 16'd64; // address for BOT
         if (word_count != 6'd0)
           wren_a_2 <= 1; // if looking at first word, EOR zeros still in accelerator, invalid output. 
         state <= BOT;
				 end

		 BOT : begin
				 shift_enable_m <= 0;
				 shift_enable_b <= 1;
				 if (oob == 1 && address_a_2 < 16'd128) begin
					address_a_2 <= address_a_2 - 16'd64 + 16'd1; // address for TOP; go back one row, move forward one word 
					memory_buffer <= q_a_2;
				 end
				 else if (oob == 1 && address_a_2 > 16'd65471) begin
					address_a_2 <= address_a_2 - 16'd128 + 16'd1; // address for TOP; go back two rows, move forward one word 
					memory_buffer <= 22'd0; // dead cell outline at bottom
				 end
				 else begin 
				   address_a_2 <= address_a_2 - 16'd128 + 16'd1; // address for TOP; go back two rows, move forward one word 
				   memory_buffer <= q_a_2;
				 end
				 word_count <= word_count + 6'd1;
				 if(word_count == 6'd63) // at end of row
				   state <= EOR;
				 else
				   state <= TOP;
				 end

		EOR : begin
				if (oob == 1 && address_a_2 < 16'd65)
				  oob <= 0;
				else if (oob == 1) begin
					frame_complete <= 1;
					direction <= 1;
				end
				memory_buffer <= 22'd0; // when to deassert write enable so this isn't the next thing written?
				shift_enable_b <= 1;
				shift_enable_m <= 1;
				shift_enable_t <= 1;
				word_count <= 6'd0; 
				state <= TOP;
				end
			   
	  endcase
	  
	end

end


  
  /*
  logic [10:0] i = 11'd0;
  logic [10:0] j = 11'd0;
  */

/*							 
	always @(direction)
	if(~direction) begin
	//read from m1, modify m2
	  for(i=0; i<1024; i++) begin
	  // push in first 0
	  //push in first 20
	  //push in next 1 bit
		for(j=0;j<1280;j=j+20) begin
		// write output from Conway_multiple to m2 in correct position
		// push in 20 bits (3 rows)
		end
		//push in last 0
	  end
	end else begin
	//read from m2, modify m1
	end
	*/
  
endmodule
