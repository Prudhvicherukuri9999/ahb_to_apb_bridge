interface ahb_interface( input bit clk,rst);
  logic [31:0]haddr;
  logic [31:0]hwdata;
  logic [31:0]hrdata;
  logic [1:0] htrans;
  logic [1:0] hresp;
  logic [2:0] hsize;
  logic [2:0] hburst;
  logic [3:0] hprot=1;
  logic [3:0] hmaster=1;
  logic hwrite;
  logic hready_in;
  logic hsel=1;
  logic hready_out;
  logic retry_enable=0;
  int check_count_1 = 0;
  int check_count_2 = 0;
  int check_count_3 = 0;
  int check_count_4 = 0;
  int check_count_5= 0;
  
//    // HTRANS should be NONSEQ or SEQ only when HREADY is high
// property p_valid_transfer;
//   @(posedge clk)
//   disable iff (!rst|| check_count > 0)
//   (hready_in && (htrans == 2'b10 || htrans == 2'b11)) |-> ##3 hready_out;
// endproperty
// assert property (p_valid_transfer)
//   begin
//   check_count++;
//   $display(" ----ASSERTION PASS---- HTRANS is NONSEQ or SEQ during valid transfer");
//   else $error("----ASSERTION FAIL---- HTRANS is not NONSEQ or SEQ during valid transfer");

property p_valid_transfer;
  @(posedge clk)
  disable iff (!rst || check_count_1 > 0)
  (hready_in && (htrans == 2'b10 || htrans == 2'b11)) |-> ##3 hready_out;
endproperty

// Assert the property only once
always @(posedge clk) begin
  if (rst && check_count_1 == 0) begin
    assert property (p_valid_transfer)
      begin
        $display("----ASSERTION PASS---- HTRANS is NONSEQ or SEQ during valid transfer");
        check_count_1++;
      end
    else begin
        $error("----ASSERTION FAIL---- HTRANS is not NONSEQ or SEQ during valid transfer");
        check_count_1++;
    end
  end
end


// HWRITE remains stable during HREADY low
property p_hwrite_stable;
  @(posedge clk)
  disable iff (!rst || check_count_2 > 0)
  !hready_out |=> $stable(hwrite);
endproperty
      
always @(posedge clk) begin
  if (rst && check_count_2 == 0) begin
    assert property (p_hwrite_stable)
      begin
        $display(" ----ASSERTION PASS----  HWRITE is stable when HREADY is low");
        check_count_2++;
      end
    else begin
        $error(" ----ASSERTION FAIL----HWRITE is not stable when HREADY is low");
		check_count_2++;
    end
  end
end
// HADDR remains stable when HREADY is low
property p_haddr_stable;
  @(posedge clk)
  disable iff (!rst || check_count_3 > 0)
  !hready_out |=> $stable(haddr);
endproperty
      
      
  always @(posedge clk) begin
    if (rst && check_count_3 == 0) begin
    assert property (p_haddr_stable)
      begin
        $display(" ----ASSERTION PASS----  HADDR is stable  when HREADY was low");
        check_count_3++;
      end
    else begin
       $error("  ----ASSERTION FAIL---- HADDR changed when HREADY was low");
		check_count_3++;
    end
  end
end

// HSIZE should not exceed word (assuming 32-bit word size)
property p_hsize_valid;
  @(negedge clk)
  disable iff (!rst || check_count_4 > 0)
  hsize <= 3'b010;
endproperty
      
      
  always @(posedge clk) begin
    if (rst && check_count_4 == 0) begin
    assert property (p_hsize_valid)
      begin
       $display(" ----ASSERTION PASS----  HSIZE exceeds maximum allowed size");
        check_count_4++;
      end
    else begin
      $error("----ASSERTION FAIL---- HSIZE exceeds maximum allowed size at time=%0t",$time);
		check_count_4++;
    end
  end
end

  property check_clktime;
      realtime current_time;
    ((1,current_time =$realtime) |-> ($realtime- current_time == 0));
     endproperty
  
  
//   assert property(  @(posedge clk) check_clktime)
//         $display($realtime," check_clktime  assertion is asserted ---passed----time=%0t",$time);
//         else
//           $error($realtime," check_clk_time assertion not asserted ---failed---- time=%0t",$time);

  
   always @(posedge clk) begin
     if (!rst && check_count_5== 0) begin
    assert property ( @(posedge clk) check_clktime)
      begin
       $display(" ----ASSERTION PASS----  HSIZE exceeds maximum allowed size");
        check_count_5++;
      end
    else begin
       $error("----ASSERTION FAIL---- HSIZE exceeds maximum allowed size");
		check_count_5++;
    end
  end
end
      endinterface