interface apb_interface(input bit clk,rst);
  logic [31:0] prdata;
  logic [31:0] pwdata;
  logic [31:0] paddr;
  logic psel;
  logic pslverr=1;
  logic pwrite;
  logic [1:0] psize;
  logic [2:0] pburst;
  logic [3:0] pbyte_en;
  logic [3:0] pprot;
  logic pread;
  logic xfer_error_access=0;
  logic pready;
endinterface