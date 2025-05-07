class ahb_agent extends uvm_agent;
  `uvm_component_utils(ahb_agent)

  ahb_sequencer ahb_sqr;
  ahb_driver ahb_drv;
  ahb_monitor ahb_mon;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function  void build_phase(uvm_phase phase);
    ahb_sqr=ahb_sequencer::type_id::create("ahb_sqr",this);
    ahb_drv=ahb_driver::type_id::create("ahb_drv",this);
    ahb_mon=ahb_monitor::type_id::create("ahb_mon",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    ahb_drv.seq_item_port.connect(ahb_sqr.seq_item_export);
  endfunction
endclass
