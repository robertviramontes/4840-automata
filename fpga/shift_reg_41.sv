// Shift register adapted from (in project notes doc)
// 41 bits of output

module shift_buffer(input logic clk, clear,
input logic shift_enable, // do shift when enabled, else hold
input [19:0] din, // 20 bits in
output [21:0] dout // 22 bits out
);

logic [40:0] sregisters;
assign dout = sregisters[40:19];
	
	always @(posedge clk) begin
		if (clear)
			sregisters = 41'd0;

		else if (shift_enable) begin
			sregisters[19:0] <= din;
			
			sregisters[40:20] <= sregisters[20:0];
			
		end else
			dout <= dout;
	end

endmodule