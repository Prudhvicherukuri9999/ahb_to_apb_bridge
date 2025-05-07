class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)
  apb_monitor apb_mon;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    apb_mon=apb_monitor::type_id::create("apb_mon",this);
  endfunction
endclass