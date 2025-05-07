`include "uvm_macros.svh"
import uvm_pkg::*;
`include "ahb_interface.sv"
`include "apb_interface.sv"
`include "ahb_sequence_item.sv"
`include "apb_sequence_item.sv"
`include "ahb_sequence.sv"
`include "ahb_sequencer.sv"
`include "ahb_driver.sv"
`include "ahb_monitor.sv"
`include "ahb_agent.sv"
`include "apb_monitor.sv"
`include "apb_agent.sv"
`include "ahb_apb_scoreboard.sv"
`include "subscriber.sv"
`include "ahb_apb_environment.sv"
`include "ahb_apb_test.sv"
`include "ahb_memory_model.sv"

module top;
  bit clk;
  bit rst;
  always #5 clk=~clk;

  ahb_interface intf1(.clk(clk),.rst(rst));
  apb_interface  intf2(.clk(clk),.rst(rst));

  gen_ahb_slvif dut(
    .ahb_clk(intf1.clk),
    .ahb_reset_n(intf1.rst),
    .ahb_slv_hmaster_i(intf1.hmaster),
    .ahb_slv_haddr_i(intf1.haddr),
    .ahb_slv_hwdata_i(intf1.hwdata),
    .ahb_slv_hwrite_i(intf1.hwrite),
    .ahb_slv_htrans_i(intf1.htrans),
    .ahb_slv_hsize_i(intf1.hsize),
    .ahb_slv_hburst_i(intf1.hburst),
    .ahb_slv_hready_i(intf1.hready_in),
    .ahb_slv_hsel_i(intf1.hsel),
    .ahb_slv_hprot_i(intf1.hprot),
    .slv_ahb_hready_o(intf1.hready_out),
    .slv_ahb_hresp_o(intf1.hresp),
    .slv_ahb_hrdata_o(intf1.hrdata),
    .retry_enable(intf1.retry_enable),
    .pread(intf2.pread),
    .paddr(intf2.paddr),
    .pwrite(intf2.pwrite),
    .pwdata(intf2.pwdata),
    .psize(intf2.psize),
    .pburst(intf2.pburst),
    .pbyte_en(intf2.pbyte_en),
    .pprot(intf2.pprot),
    .slv_ahb_sel(intf2.psel),
    .slv_ahb_rdata(intf2.prdata),
    .xfer_error_access(intf2.xfer_error_access),
    .slv_ahb_ack(intf2.psel&|intf2.pbyte_en));

  mem dut1(.clk(intf2.clk),
           .rst(intf2.rst),
           .paddr(intf2.paddr),
           .pwdata(intf2.pwdata),
           .psel(intf2.psel),
           .penable(intf2.pbyte_en),
           .pwrite(intf2.pwrite),
           .pread(intf2.pread),
           .prdata(intf2.prdata),
           .pready(intf2.pready));


  assign intf1.hready_in=intf1.hready_out;

  initial begin
    uvm_config_db#(virtual ahb_interface)::set(null,"*","active",intf1);
    uvm_config_db#(virtual apb_interface)::set(null,"*","passive",intf2);
    run_test("ahb_apb_test");

  end

  initial begin

    clk=0;
    rst=1;
    #2
    rst=0;
    #2
    rst=1;
    $display("random seed=%0d",$get_initial_random_seed);
  end
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
endmodule






