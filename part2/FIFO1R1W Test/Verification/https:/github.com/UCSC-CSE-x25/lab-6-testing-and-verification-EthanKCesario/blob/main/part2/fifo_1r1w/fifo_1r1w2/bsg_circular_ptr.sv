`include "bsg_defines.v"
// MBT
//
// 10/27/14
//
// implements a circular pointer that
// can be incremented by at most max_add_p
// and points to slots_p slots.
//

module bsg_circular_ptr #(parameter `BSG_INV_PARAM(slots_p)
                          , parameter `BSG_INV_PARAM(max_add_p)
                          // local param
                          , parameter ptr_width_lp = `BSG_SAFE_CLOG2(slots_p)
			  )
   (input clk
    , input reset_i
    , input  [$clog2(max_add_p+1)-1:0] add_i
    , output [ptr_width_lp-1:0] o
    , output [ptr_width_lp-1:0] n_o
    );

   logic [ptr_width_lp-1:0] ptr_r, ptr_n, ptr_nowrap;
   logic [ptr_width_lp:0]   ptr_wrap;

   assign o = ptr_r;
   assign n_o = ptr_n;

   // increment round robin pointers

   // synopsys sync_set_reset "reset_i"
   always_ff @(posedge clk)
     if (reset_i) ptr_r <= 0;
     else       ptr_r <= ptr_n;

   if (slots_p == 1)
     begin
	assign ptr_n = 1'b0;
	wire ignore = |add_i;
     end
   else
   
     // fixme performance optimization:
     // we should handle add-by-1 and non-power-of-two
     // in the same way as power-of-two and add-by-1
     // with a compare of ptr_r to slots_p-1 to check for
     // zeroing the ptr_r_p1 value.
     
    if (`BSG_IS_POW2(slots_p))
       begin
	  // reduce critical path on add_i signal
	  if (max_add_p == 1)
	    begin
	       wire [ptr_width_lp-1:0] ptr_r_p1 = ptr_r + 1'b1;
	       assign  ptr_n = add_i ? ptr_r_p1 : ptr_r;
	    end
	  else
	    assign  ptr_n = ptr_width_lp ' (ptr_r + add_i);
       end
     else
       begin: notpow2
          // compute wrapped and non-wrap cases
          // in parallel
          assign ptr_wrap = (ptr_width_lp+1)'({ 1'b0, ptr_r } - slots_p + add_i);
          assign ptr_nowrap = ptr_r + add_i;

          // if (ptr_r + add_i - slots_p >= 0)
          // then we have wrapped around
          assign ptr_n = ~ptr_wrap[ptr_width_lp] ? ptr_wrap[0+:ptr_width_lp] : ptr_nowrap;
end
endmodule // bsg_circular_ptr

`BSG_ABSTRACT_MODULE(bsg_circular_ptr)