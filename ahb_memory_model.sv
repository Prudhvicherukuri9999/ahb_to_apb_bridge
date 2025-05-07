module mem(clk,rst,paddr,pwdata,psel,penable,pwrite,pread,prdata,pready);
  input clk,rst,psel,pwrite,pread;
  input [31:0]paddr;
  input [31:0]pwdata;
  input[3:0]penable;
  output reg pready;
  output reg [31:0]prdata;
  reg[0:31]mem[0:255];
  assign pready=1;
  always@(posedge clk or negedge rst)
    begin
      if(!rst)
        begin
          for(int i=0;i<255;i++)
            mem[i]<=0;
        end
      else if(psel&&( |penable)&& pwrite)
        begin
          mem[paddr]<=pwdata;
          //           $display("slave_memory");
          //           $display("mem[%0d]=%0p",paddr,mem[paddr]);
          //           $display(pwdata);

        end
      else if(psel&&(|penable)&&pread)
        begin
          prdata<=mem[paddr];
        end
    end

endmodule