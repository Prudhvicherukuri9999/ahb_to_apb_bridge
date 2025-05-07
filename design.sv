// =============================================================================
// PRoject Name     : generic_ahb_slvif
// =============================================================================
// Description:
// This is a generic AHB slave interface module that can be integrated into
// any IP seamlessly.
// Features:
// Supports ERROR response
// Supports RETRY response
// 
// 
// ====================================================================                                      
module gen_ahb_slvif (
   // Outputs
   slv_ahb_hready_o, slv_ahb_hresp_o, slv_ahb_hrdata_o, pread, paddr, pwrite, pwdata, 
   psize, pburst, pbyte_en, pprot, slv_ahb_sel, 
   // Inputs
   ahb_clk, ahb_reset_n, ahb_slv_hmaster_i, ahb_slv_haddr_i, ahb_slv_hwdata_i, ahb_slv_hwrite_i, ahb_slv_htrans_i, 
   ahb_slv_hsize_i, ahb_slv_hburst_i, ahb_slv_hready_i, ahb_slv_hsel_i, ahb_slv_hprot_i,
    slv_ahb_ack, slv_ahb_rdata, 
   xfer_error_access,retry_enable
   );
   
input ahb_clk;
input ahb_reset_n;
input retry_enable;
 	
// AHB slave interface.
   input [3:0]  ahb_slv_hmaster_i;
   input [31:0] ahb_slv_haddr_i;
   input [31:0] ahb_slv_hwdata_i;
   input 		ahb_slv_hwrite_i;
   input [1:0]  ahb_slv_htrans_i;
   input [2:0]  ahb_slv_hsize_i;
   input [2:0]  ahb_slv_hburst_i;
   input 		ahb_slv_hready_i;
   input        ahb_slv_hsel_i;
   input [3:0] 	ahb_slv_hprot_i;
   output 		slv_ahb_hready_o;
   output [1:0] slv_ahb_hresp_o;
   output [31:0]slv_ahb_hrdata_o;

// LPCif/DMA/BOOT csr interface.
   output 	      	  pread;
   output [31:0]      paddr;		
   output 	          pwrite;
   output [31:0]      pwdata;
   output [1:0]       psize;
   output [2:0]       pburst;
   output [3:0]       pbyte_en;
   output [3:0]       pprot;
   output        	  slv_ahb_sel;
   
   input 			  slv_ahb_ack;
   input [31:0] 	  slv_ahb_rdata;
   input        	  xfer_error_access;

   reg [1:0] 		  psize;
   reg [2:0] 		  pburst;
   reg  	          psel;
   reg [3:0]          pprot;
   reg [1:0]	      slv_ahb_hresp_o;


// parameter declarations
parameter       AHB_OKAY    = 2'b00,
                AHB_ERROR   = 2'b01,
                AHB_RETRY   = 2'b10,
                AHB_SPLIT   = 2'b11;

parameter       IDLE    = 2'b00,
                BUSY    = 2'b01,
                NONSEQ  = 2'b10,
                SEQ     = 2'b11;

parameter       SINGLE  = 3'b000,
                INCR    = 3'b001,
                INCR4   = 3'b011,
                INCR8   = 3'b101,
                INCR16  = 3'b111;

/* no support for WRAP xfers */

parameter 		BYTE    = 3'b000,
                HWORD   = 3'b001,
                WORD    = 3'b010;

   reg          pwrite_p1;
   reg			pread;
   reg [31:0] 	paddr;		
   reg			pwrite;
   reg [3:0] 	pbyte_en;
   reg [31:0] 	slv_ahb_hrdata_o;
   reg 			slv_ahb_hready_o;
   
   reg 			data_stage;
   wire [31:0] 	pwdata;
   
   reg [3:0] 	current_hmaster;
   reg [3:0] 	retry_pend_hmaster;
   reg       	assert_retry_reg_d;
   reg       	xfer_error_access_d ;
   reg 			ahs_ack;
   reg 			ahb_xfer_dphase;
   reg  		hmaster_match_d;
   wire  		hmaster_match;
   wire 		ahb_xfer_done;
   wire  		ahs_ack_combo;
  
   
//-------------------------------------------------------------
// Select logic for hsel. This should locate to the address map
// All unmapped addresses should give an error response
//-------------------------------------------------------------


   reg 			ahb_addr_phase;
   reg 			assert_retry_reg;
/* LPC Hresp generation Logic */
// RTBD: 0909 what is the response for xfer_error_access?
// every tranfer is minumum of 3 cycles for dataphase when the data/ack is not available
// whenever the data is available, OKAY response is given 
// when the data is not available RTRY resp is given & ERR resp is given 
// if protected or out of range addr 
/* commented on Oct25th
   always @(posedge ahb_clk or negedge ahb_reset_n)
     begin
	if(~ahb_reset_n)
	  begin
	     slv_ahb_hresp <= AHB_OKAY;
	  end
	else if(ahb_xfer_dphase || ahb_addr_phase) begin
             // xfer_error_access should be asserted atleast two cycles
             if (xfer_error_access) begin
	        slv_ahb_hresp <= AHB_ERROR;
             end
	     //else if((assert_retry_reg && (hmaster_match || hmaster_match_d) && (ahs_ack || ahs_ack_combo)) ||
	     // else if((assert_retry_reg && (hmaster_match || hmaster_match_d) && ahs_ack) || -- commented oct25
	     else if((!assert_retry_reg && (hmaster_match || hmaster_match_d) && ahs_ack) ||
//                     (ahb_addr_phase && !ahb_xfer_done) ||
		     // this below term is to drive okay after the dphase
	             (ahb_xfer_done && ahb_xfer_dphase)) begin 
	        slv_ahb_hresp <= AHB_OKAY;
    	     end 
             // assert_retry_reg should be asserted atleast two cycles
	     else if(assert_retry_reg)  begin
	        slv_ahb_hresp <= AHB_RETRY;
    	     end 
	     else begin
	        slv_ahb_hresp <= AHB_OKAY;
    	     end 
	end
	else if(slv_ahb_hready_i) // not slv_ahb ahb dataphase
	  begin
	     slv_ahb_hresp <= AHB_OKAY;
	  end
     end // 

*/

   always @(posedge ahb_clk or negedge ahb_reset_n)
      begin
	if(~ahb_reset_n)
	  begin
	     slv_ahb_hresp_o <= AHB_OKAY;
	  end
	else if(ahb_addr_phase) begin
        // added error case on 1509 to take care of error case in address phase
          if (hmaster_match && (xfer_error_access_d || xfer_error_access)) begin
	     slv_ahb_hresp_o <= AHB_ERROR;
          end
	  else if (hmaster_match && (ahs_ack || ahs_ack_combo)) begin
	     slv_ahb_hresp_o <= AHB_OKAY;
    	  end 
	  else if(assert_retry_reg)  begin
	     slv_ahb_hresp_o <= AHB_RETRY;
          end
          else begin
	     slv_ahb_hresp_o <= AHB_OKAY;
          end
        end
	else if(ahb_xfer_dphase) begin
             // xfer_error_access should be asserted atleast two cycles
             if (ahb_slv_hready_i ) begin	 
	        slv_ahb_hresp_o <= AHB_OKAY;
             end
	     else if(assert_retry_reg && (slv_ahb_hresp_o != AHB_ERROR))  begin
	        slv_ahb_hresp_o <= AHB_RETRY;
    	     end 
             //else if (!assert_retry_reg && (xfer_error_access || xfer_error_access_d)) begin
             else if (xfer_error_access || xfer_error_access_d) begin
	        slv_ahb_hresp_o <= AHB_ERROR;
             end
             // this statement is to take care when not error/retry xfer
	     //else begin
	        //slv_ahb_hresp <= AHB_OKAY;
    	     //end 
	end
	else if(ahb_slv_hready_i) // not slv_ahb ahb dataphase
	  begin
	     slv_ahb_hresp_o <= AHB_OKAY;
	  end
     end // 

   always @(posedge ahb_clk or negedge ahb_reset_n)
     begin
	if(~ahb_reset_n)
	  begin
	     ahb_xfer_dphase <= 1'b0;
             hmaster_match_d <= 1'b0;
	  end
	else if(ahb_slv_hsel_i && ahb_slv_hready_i && (ahb_slv_htrans_i != 2'b00))
	  begin
	     ahb_xfer_dphase <= 1'b1;
             hmaster_match_d <= hmaster_match;
          end
	else if(ahb_slv_hready_i)
	  begin
	     ahb_xfer_dphase <= 1'b0;
             hmaster_match_d <= 1'b0;
          end
     end

/* fw_access_ack creates corner case if it comes while ahb xfer is in progress */
/* Need to take care of this condition RAJANI - TBD */   
/* Need to generate a dataphase qualifying signal - RAJANI - TBD*/

   always @(ahb_slv_hsel_i or ahb_slv_htrans_i or ahb_slv_hready_i)
     begin
	ahb_addr_phase = 0;
	if((ahb_slv_hsel_i) && (ahb_slv_htrans_i !=0) && ahb_slv_hready_i)
	  begin
	      ahb_addr_phase = 1;   
	  end // if (slv_ahb_boot_hsel && (slv_ahb_htrans !=0) && slv_ahb_hready)
     end // always @ (slv_ahb_haddr or slv_ahb_hsize or slv_ahb_hsel or slv_ahb_htrans or slv_ahb_hready)

   always @*
     begin
        if ((ahb_slv_hsel_i) && ahb_slv_hready_i) begin
	   current_hmaster[3:0] <= ahb_slv_hmaster_i[3:0];
        end
        else begin // if hmaster 0 is allowed, the value should be zero instead of inversion
	   current_hmaster[3:0] <= ~ahb_slv_hmaster_i[3:0];
        end
     end
  
   always @(posedge ahb_clk or negedge ahb_reset_n)
     begin
	if (!ahb_reset_n) begin
	   assert_retry_reg_d <= 1'b0;
	   xfer_error_access_d <= 1'b0;
	end
        else begin
	   assert_retry_reg_d <= assert_retry_reg;
           if (ahb_xfer_done) xfer_error_access_d <= 1'b0;
           else if (xfer_error_access) xfer_error_access_d <= 1'b1;
        end
     end

   //always @(posedge ahb_clk or negedge ahb_reset_n)
   //  begin
   //     if (!ahb_reset_n) begin
   //        retry_pend_hmaster[3:0] <= 4'h0;
   //     end
   //     else if (assert_retry_reg & ~assert_retry_reg_d) begin
   //        retry_pend_hmaster[3:0] <= ahb_slv_hmaster_i[3:0];
   //     end
   //  end

   assign hmaster_match = ahb_addr_phase && (current_hmaster[3:0] == retry_pend_hmaster[3:0]);
   // Added AHB ERROR term on 1509 to take care of Error cases
   assign ahb_xfer_done = slv_ahb_hready_o && ahb_xfer_dphase && ((slv_ahb_hresp_o == AHB_OKAY) || (slv_ahb_hresp_o == AHB_ERROR));  // added lpc hresp term 26th Oct

   always @(posedge ahb_clk or negedge ahb_reset_n)
     begin
	if (ahb_reset_n == 0) begin
	     assert_retry_reg<= 0;
             retry_pend_hmaster[3:0] <= 4'h0; // added for Burst support 
	end
        else if (!retry_enable ) begin
	    assert_retry_reg<=  1'b0 ;
            retry_pend_hmaster[3:0] <= 4'h0; // added for Burst Support 
	end
          //else if (retry_enable && ahb_addr_phase && !ahs_ack) begin
// 23rd Sep changed the reseting bit as priority than setting it.
// removed !ahs_ack signal in setting logic
	else if (((ahs_ack || ahs_ack_combo) && hmaster_match && assert_retry_reg) || xfer_error_access_d) begin
	    assert_retry_reg<=  1'b0 ;
	end
        else if (retry_enable && ahb_addr_phase ) begin
	    assert_retry_reg<=  1'b1 ;
            // Added for Burst Support
            retry_pend_hmaster[3:0] <= ahb_slv_hmaster_i[3:0];//Assigning retry_pend_hmaster in addr phase itself
	end
     end 
   
//If multiple slaves are added, need to add more ACKs
// Example: assign ahs_ack_combo = (boot_data_avail || gen_if_ack || dma_csr_ack || gen_ram_ack);
assign ahs_ack_combo = (slv_ahb_ack);

// ahs_ack is a level signal will be high until the xfer completes on AHB
always @ (posedge ahb_clk or negedge ahb_reset_n)
  begin
     if (ahb_reset_n == 0) begin
	  ahs_ack <= 1'b0;
     end
     else if(ahs_ack_combo) begin
	  ahs_ack <= 1'b1;
     end
     else if(ahb_xfer_dphase && ahb_xfer_done && (!retry_enable || hmaster_match_d)) begin
	  ahs_ack <= 1'b0;
     end
    //else
    // ahs_ack <= 1'b0;  
 
  end


always @ (posedge ahb_clk or negedge ahb_reset_n)
  begin
     if (ahb_reset_n == 0) begin
	  slv_ahb_hready_o <= 1'b1;
     end
     else if (ahb_slv_hsel_i && ahb_slv_hready_i && (ahb_slv_htrans_i != IDLE)) begin
	  slv_ahb_hready_o <= 1'b0;
     end
//     else if(assert_retry_reg_d|| (ahs_ack || ahs_ack_combo)|| xfer_error_access_d ) begin
     else if(assert_retry_reg_d || (ahs_ack) || xfer_error_access_d) begin
          slv_ahb_hready_o <= 1'b1;
     end
     else if (ahb_slv_hready_i && (ahb_slv_htrans_i == IDLE)) begin	 
	  slv_ahb_hready_o <= 1'b1;
     end    

  end
   
//-------------------------------------------------------------
// the read data logic is registered version of prdata based on
// address selection. 
//-------------------------------------------------------------

always @ (posedge ahb_clk or negedge ahb_reset_n)
  begin
     if (ahb_reset_n == 0)
       begin
	  slv_ahb_hrdata_o <= 0;
       end
     else if (xfer_error_access)
      begin
          slv_ahb_hrdata_o <= 32'hffffffff;
      end
     else if (slv_ahb_ack)
       begin
	  slv_ahb_hrdata_o <= {slv_ahb_rdata[31:0]};	  
       end     
/*     else if (dma_csr_ack)
       begin
	  slv_ahb_hrdata <= {dma_csr_rdata[31:0]};	  
       end     */
  end

//-------------------------------------------------------------
// the write data is simply passed through. There will not be 
// staging as it comes in the next cycle on the bus.
//-------------------------------------------------------------

 assign  pwdata = ahb_slv_hwdata_i[31:0];
   
//-------------------------------------------------------------
// Driving signals of peripheral.
// Byte enables are generated according to big endian machine 
//------------------------------------------------------------

always @ (posedge ahb_clk  or negedge ahb_reset_n)
  begin
     if (ahb_reset_n  == 0)
       begin
	  paddr <= 0;
	  pread <= 0;
	  pwrite <= 0;
	  pbyte_en <= 0;
	  psize <= 0;	  
	  pburst <= 0;
          pprot <= 1'b0;
       end
      //else if ((slv_ahb_hsel|| slv_ahb_boot_hsel) && slv_ahb_hready_i && (slv_ahb_htrans != IDLE) && !xfer_error_access)
      else if (ahb_slv_hsel_i && ahb_slv_hready_i && (ahb_slv_htrans_i != IDLE) && !xfer_error_access && !assert_retry_reg)
       begin
          paddr <= ahb_slv_haddr_i[31:0];
	  pread <= !ahb_slv_hwrite_i;
	  pwrite <= ahb_slv_hwrite_i;
	  psize[1:0] <= ahb_slv_hsize_i[1:0];
	  pburst[2:0] <= ahb_slv_hburst_i[2:0];
          pprot       <= ahb_slv_hprot_i[3:0];

	  // byte enable logic based on HSIZE
     	  case (ahb_slv_hsize_i)
	  BYTE:
	  begin
	      case (ahb_slv_haddr_i[1:0])
		2'b11:
		   pbyte_en <= 4'b1000;
		2'b10:
		   pbyte_en <= 4'b0100;
		2'b01:
		   pbyte_en <= 4'b0010;
		2'b00:
		   pbyte_en <= 4'b0001;
	      endcase
	  end
          HWORD:
          begin
	      case (ahb_slv_haddr_i[1])
		1'b1:
		   pbyte_en <= 4'b1100;
		1'b0:
		   pbyte_en <= 4'b0011;
	      endcase
          end
          default:
          begin
	      pbyte_en <= 4'b1111;
          end
	  endcase
       end // if (hsel && hready_i && (htrans != IDLE))
      else if ((ahs_ack && ahb_xfer_done && !assert_retry_reg) || xfer_error_access_d)
	begin
	  paddr <= 0;
	  pread <= 0;
	  pwrite <= 0;
	  pbyte_en <= 0;
	  psize <= 0;
	  pburst <= 0;
          pprot <= 1'b0;
	end   
  end // always @ (posedge ahb_clk  or negedge ahb_reset_n)

// Generation of slv_sel signal
// Note: if there are multiple modules to be accessed via AHB SLave like
// RAM, CSR etc, multiple SELs can be generated here

//assign {boot_xfer_sel,dma_csr_sel,slv_ahb_ram_sel,slv_ahb_if_sel} = (ahs_ack && ahb_xfer_done) ? 4'h0 : psel[3:0];

assign slv_ahb_sel = (ahs_ack && ahb_xfer_done) ? 1'b0 : psel;

   always @(posedge ahb_clk or negedge ahb_reset_n)
     begin
	if(~ahb_reset_n)
	  begin
	     psel <= 1'b0;
	  end
/*	else if (slv_ahb_boot_hsel && slv_ahb_hready_i && (slv_ahb_htrans != IDLE) && !assert_retry_reg )
	  begin
	      psel <= 4'b1000;   // boot if sel
	  end
*/
	else if (ahb_slv_hsel_i && ahb_slv_hready_i && (ahb_slv_htrans_i != IDLE) && !assert_retry_reg)
	  begin
	     psel <= 1'b1; 
	  end
	else if((ahs_ack && ahb_xfer_done && !assert_retry_reg) || (ahb_xfer_done && xfer_error_access_d))
        // - commented on 1509 to take care of psel de-assertion in Error cases
//	else if(ahs_ack && ahb_xfer_done && !assert_retry_reg)
	  begin
	     psel <= 1'b0;
	  end

     end // always @ (posedge ahb_clk or negedge ahb_reset_n)

endmodule




// module memory(wdata,rdata,addr,wenable,clk,rst,renable,mem_sel,mem_enable);
//   input [31:0] wdata;
//   input [9:0]addr;
//   input mem_enable;
//   input wenable;
//   input renable;
//   input mem_sel;
//  // output ack_mem;
//  // reg ack;
//   input clk;
//   input rst;
//   output reg [31:0] rdata;
//   integer i;
  
//   reg [31:0]mymem[1023:0];
//    // assign ack_mem=ack;
//   always @(posedge clk or negedge rst)
//       begin
//         if(!rst)
//           begin
//             for(i=0;i<1024;i++)
//               begin
//                 mymem[i] <=0;
//                  //ack<=1;
//                 rdata<=0;
//               end
//           end
//         else if(wenable==1'b1 & mem_sel ==1& mem_enable==1)
//           begin
//             //ack<=1;
//             mymem[addr]<=wdata;
          
//           end
        
//         else if (renable==1'b1 &  mem_sel ==1& mem_enable==1)
//             begin
//                //ack<=1;
//           rdata<=mymem[addr];
//             end
       
//       end
// endmodule
      