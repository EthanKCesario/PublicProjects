module fifo_1r1w
  #(parameter [31:0] width_p = 8
   // Note: Not depth_p! depth_p should be 1<<depth_log2_p
   ,parameter [31:0] depth_log2_p = 8
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [width_p - 1:0] data_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o
  ,output [0:0] valid_o
  ,output [width_p - 1:0] data_o
  ,input [0:0] ready_i
  );
  
  logic [(depth_log2_p-1):0] next, len;
  logic [((depth_log2_p)):0] rd_pointer, wr_pointer, r_ptr, wr_ptr;
  logic [width_p-1:0] out1_o, out2_o;
  logic [0:0] e_r, l_w;

  wire [0:0] max, out;

  ram_1r1w_sync #(
    .width_p(width_p),
    .depth_p(1<<depth_log2_p))
    ram_1r1w_sync_inst ( 

    .clk_i(clk_i),
    .reset_i(reset_i),
    .wr_valid_i(valid_i & ready_o),
    .wr_data_i(data_i),
    .wr_addr_i(wr_ptr[depth_log2_p-1:0]),
    .rd_addr_i(rd_pointer[depth_log2_p-1:0]),
    .rd_data_o(out1_o),
    .rd_valid_i(valid_o)
  );


 elastic #(.width_p(width_p))
 elastic_inst(
  .clk_i(clk_i)
  ,.reset_i(reset_i)
  ,.data_i(data_i)
  ,.valid_i(valid_i & ready_o)
  ,.ready_o(ready_o)
  ,.data_o(out2_o)
  );
   
 always_comb begin
    next = len;
    rd_pointer = r_ptr;
    wr_pointer = wr_ptr;
    e_r = 1'b1;
    if ((valid_i & ready_o) & (valid_o & ready_i)) begin
      wr_pointer++;  
      rd_pointer++;
      if((rd_pointer == wr_ptr) & l_w) begin
        e_r = 1'b1;
      end else begin
        e_r = 1'b0;
      end
    end
    else if(valid_o & ready_i) begin
      next = len - 1;
      rd_pointer++;;    
      if((rd_pointer == wr_ptr) & l_w) begin
        e_r = 1'b1;
      end else begin
        e_r = 1'b0;
      end
    end
    else if (valid_i & ready_o) begin
      next = len + 1; 
      wr_pointer++;      
    end
  end
 
  assign max = (wr_ptr[depth_log2_p-1:0] == r_ptr[depth_log2_p-1:0]) & (wr_ptr[depth_log2_p] != r_ptr[depth_log2_p]); 
  assign out = wr_ptr == r_ptr;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      len <= '0;
      r_ptr <= '0;
      wr_ptr <= '0;
    end else begin
      len <= next;
      r_ptr <= rd_pointer;
      wr_ptr <= wr_pointer;
    end
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      l_w <= '0;
    end
      l_w <= (valid_i & ready_o);
  end

  assign data_o = (~e_r) ?  out1_o : out2_o;
  assign valid_o = ~out;
  assign ready_o = ~max;
 
endmodule