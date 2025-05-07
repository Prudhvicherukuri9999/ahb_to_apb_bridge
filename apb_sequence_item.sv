class apb_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(apb_sequence_item)

  rand bit [31:0] paddr;
  rand bit [31:0] pwdata[];
  rand bit [31:0] prdata[];
  rand bit        pwrite;
  rand bit [2:0]  pburst;

  function new(string name="");
    super.new(name);
  endfunction

endclass