
class ahb_monitor extends uvm_monitor;
  `uvm_component_utils(ahb_monitor)

  virtual ahb_interface intf1;
  ahb_sequence_item seq_item;
  uvm_analysis_port#(ahb_sequence_item) seq1_put;
  int length;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ahb_interface)::get(this, "", "active", intf1))
      `uvm_fatal("AHB_MON", "Failed to get AHB virtual interface")
      seq1_put = new("seq1_put", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item = ahb_sequence_item::type_id::create("seq_item");
      wait_for_start();
      if (intf1.hwrite)
        ahb_write(seq_item);
      else
        ahb_read(seq_item);
    end
  endtask

  task wait_for_start();
    forever begin
      @(posedge intf1.clk);
      if (intf1.hready_out && intf1.htrans == 2'b10)
        break;
    end
  endtask

  task wait_for_beat();
    forever begin
      @(posedge intf1.clk);
      if (intf1.hready_out && intf1.htrans == 2'b11)
        break;
    end
  endtask

  task wait_for_end();
    forever begin
      @(posedge intf1.clk);
      if (intf1.hready_out && intf1.htrans == 2'b00)
        break;
    end
  endtask

  task ahb_write(ahb_sequence_item item);
    item.hburst = intf1.hburst;
    item.hsize  = intf1.hsize;
    item.haddr  = intf1.haddr;
    item.hwrite = 1;
    item.htrans = intf1.htrans;

    case (item.hburst)
      3: length = 4;  // burst length for INCR8
      default: length = 1; // default for single transfer
    endcase

    item.hwdata = new[length];

    foreach (item.hwdata[i]) begin
      wait_for_beat();
      item.hwdata[i] = intf1.hwdata;
    end
    wait_for_end();

    seq1_put.write(item);
  endtask

  task ahb_read(ahb_sequence_item item);
    item.hburst = intf1.hburst;
    item.hsize  = intf1.hsize;
    item.haddr  = intf1.haddr;
    item.hwrite = 0;
    item.htrans = intf1.htrans;

    case (item.hburst)
      3: length = 4;  // burst length for INCR8
      default: length = 1; // default for single transfer
    endcase

    item.hrdata = new[length];

    foreach (item.hrdata[i]) begin
      wait_for_beat();
      item.hrdata[i] = intf1.hrdata;
    end
    wait_for_end();

    seq1_put.write(item);
  endtask
endclass
