// Shift register adapted from (in project notes doc)
// 41 bits of output

module shift_buffer(input logic clk, clear,
input logic shift_enable, // do shift when enabled, else hold
input logic restrict_size, // shift by 1 when enabled, else shift by 20
input [19:0] din, // 20 bits in
output [21:0] dout // 22 bits out
);

	always @(posedge clk) begin
		if (clear)
			dout <= 22'd0;
		else if (shift_enable) begin
			if (restrict_size) begin
				// shift by 1
				dout[21:1] <= dout[20:0];
				dout[0] <= din[19];
			end else begin
				// do the shift
				dout[21:20] <= dout[1:0];
				dout[19:0] <= din[19:0];
			end
		end else
			dout <= dout;
	end

endmodule