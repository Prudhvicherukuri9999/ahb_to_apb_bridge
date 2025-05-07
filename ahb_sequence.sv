class ahb_sequence extends uvm_sequence#(ahb_sequence_item);
  `uvm_object_utils(ahb_sequence)
  ahb_sequence_item seq_item;
  int local_addr;
  function new(string name="ahb_sequence");
    super.new(name);
  endfunction
  task body();
    `uvm_info(get_full_name(),$sformatf("inside ahb sequnce body method"),UVM_LOW)
    seq_item=ahb_sequence_item::type_id::create("seq_item");//write operation
    wait_for_grant();
    assert(seq_item.randomize() with {hwrite==1;hburst==3;hsize==2;});
    local_addr=seq_item.haddr;
    send_request(seq_item);
    `uvm_info(get_full_name(),$sformatf("ahb write sequence hwdata=%0p",seq_item.hwdata),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb write sequence haddr=%0p",seq_item.haddr),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb write sequence htrans=%0p",seq_item.htrans),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb write sequence hsize=%0p",seq_item.hsize),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb write sequence hwrite=%0p",seq_item.hwrite),UVM_LOW)
    `uvm_info(get_type_name(), "-------------------------------------------------------", UVM_NONE)
    wait_for_item_done();

    seq_item=ahb_sequence_item::type_id::create("seq_item");//read operation
    wait_for_grant();
    assert(seq_item.randomize() with {hwrite==0;hburst==3;hsize==2;haddr==local_addr;});
    send_request(seq_item);
    `uvm_info(get_full_name(),$sformatf("ahb read sequence hwrite=%0p",seq_item.hwrite),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb read sequence haddr=%0p",  seq_item.haddr),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb read sequence htrans=%0p",seq_item.htrans),UVM_LOW)
    `uvm_info(get_full_name(),$sformatf("ahb read sequence hsize=%0p", seq_item.hsize),UVM_LOW)
    `uvm_info(get_type_name(), "-------------------------------------------------------", UVM_NONE)
    wait_for_item_done();
  endtask

endclass


