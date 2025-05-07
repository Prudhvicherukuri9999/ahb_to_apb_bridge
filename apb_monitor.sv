class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_interface intf2;
  apb_sequence_item seq_item;
  uvm_analysis_port#(apb_sequence_item) seq2_put;
  int length;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_interface)::get(this, "", "passive", intf2))
      `uvm_fatal("MON", "Failed to get APB virtual interface")
      seq2_put = new("seq2_put", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge intf2.clk);
      if (intf2.psel && intf2.pready && |intf2.pbyte_en) begin
        seq_item = apb_sequence_item::type_id::create("seq_item");
        // Sample pwrite first to determine transaction type
        seq_item.pwrite = intf2.pwrite;
        if (seq_item.pwrite) begin
          apb_write(seq_item);
          `uvm_info("APB_MON_WRITE", $sformatf("APB Address: 0x%0h, pwdata=%p", seq_item.paddr, seq_item.pwdata), UVM_LOW);
        end
        else begin
          apb_read(seq_item);
          `uvm_info("APB_MON_READ", $sformatf("APB Address: 0x%0h, prdata=%p", seq_item.paddr, seq_item.prdata), UVM_LOW);
        end
      end
    end
  endtask

  task apb_write(apb_sequence_item item);
    item.paddr = intf2.paddr;
    item.pwrite = 1;
    item.pburst = intf2.pburst;
    case (item.pburst)
      3: length = 4;
      default: length = 1;
    endcase
    item.pwdata = new[length];
    for (int i = 0; i < length; i++) begin
      wait_for_valid_transfer();
      // wait_for_valid_transfer();
      //@(posedge intf2.clk);
      @(posedge intf2.clk); // Wait one cycle for pwdata to stabilize
      item.pwdata[i] = intf2.pwdata;
      `uvm_info("APB_MON", $sformatf("Burst beat %0d: psel=%b, pready=%b, pbyte_en=%b, paddr=0x%0h, pwdata=0x%0h",
                                     i, intf2.psel, intf2.pready, |intf2.pbyte_en, intf2.paddr, intf2.pwdata), UVM_LOW);
    end
    seq2_put.write(item);
  endtask

  task apb_read(apb_sequence_item item);
    item.paddr = intf2.paddr;
    item.pwrite = 0;
    item.pburst = intf2.pburst;
    case (item.pburst)
      3: length = 4;
      default: length = 1;
    endcase
    item.prdata = new[length];
    for (int i = 0; i < length; i++) begin
      wait_for_valid_transfer();
      @(posedge intf2.clk); // Wait one cycle for prdata to stabilize
      item.prdata[i] = intf2.prdata;
      `uvm_info("APB_MON", $sformatf("Burst beat %0d: psel=%b, pready=%b, pbyte_en=%b, paddr=0x%0h, prdata=0x%0h",
                                     i, intf2.psel, intf2.pready, |intf2.pbyte_en, intf2.paddr, intf2.prdata), UVM_LOW);
    end
    seq2_put.write(item);
  endtask

  task wait_for_valid_transfer();
    forever begin
      @(posedge intf2.clk);
      if (intf2.psel && intf2.pready && |intf2.pbyte_en)
        break;
    end
  endtask
endclass


