module Conway_Cell( 
  input wire [2:0] top_row, middle_row, bottom_row,
  output reg next_state
);
  
  logic [1:0] sum_l, sum_c, sum_r;
  logic [3:0] sum;
  
  
    assign sum_t = top_row[2] + top_row[1] + top_row[0];
    assign sum_m = middle_row[2] + middle_row[1] + middle_row[0];
    assign sum_b = bottom_row[2] + bottom_row[1] + bottom_row[0];
  
    assign sum = sum_t + sum_m + sum_b;
  
  always @ (sum)
    if ( middle_row[1] == 1) begin
      if ( sum == 4'd3 || sum == 4'd4) 
        next_state = 1;
      else
        next_state = 0;
    end
    else begin
      if ( sum == 4'd3)
        next_state = 1;
      else
        next_state = 0;
    end
  
  endmodule
