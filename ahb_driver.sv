class ahb_driver extends uvm_driver#(ahb_sequence_item);
  `uvm_component_utils(ahb_driver)
  ahb_sequence_item seq_item;
  virtual ahb_interface intf1;
  int length;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual ahb_interface)::get(this,"","active",intf1))
      `uvm_fatal("the ahb_interface","get to ahb driver");
  endfunction
  task run_phase(uvm_phase phase);
    @(negedge intf1.rst);
    @(posedge intf1.rst);
    forever
      begin

        seq_item_port.get_next_item(seq_item);

        if(seq_item.hwrite==1)
          begin
            ahb_write1(seq_item);
            `uvm_info(get_full_name(),$sformatf("ahb driver write hwdata=%0p",seq_item.hwdata),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver write haddr=%0p",seq_item.haddr),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver write htrans=%0p",seq_item.htrans),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver write hsize=%0p",seq_item.hsize),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver write hwrite=%0p",seq_item.hwrite),UVM_LOW)
            `uvm_info(get_type_name(), "-------------------------------------------------------", UVM_NONE)
          end
        else
          begin
            ahb_read1(seq_item);
            `uvm_info(get_full_name(),$sformatf("ahb driver read haddr=%0p",seq_item.haddr),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver read htrans=%0p",seq_item.htrans),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver read hsize=%0p",seq_item.hsize),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf("ahb driver read hwrite=%0p",seq_item.hwrite),UVM_LOW)
            `uvm_info(get_type_name(), "-------------------------------------------------------", UVM_NONE)
          end
        seq_item_port.item_done();
      end
  endtask

  task clk_task();
    forever
      begin

        @(posedge intf1.clk);
        if(intf1.hready_out==1) begin

          break;
        end
      end
  endtask

  task ahb_write1(ahb_sequence_item seq_item);

    //     if(seq_item.hburst==0)
    //        length=1;
    //   else if(seq_item.hburst==1)
    //       length=2;
    if (seq_item.hburst==3)
      length=4;
    //     else if (seq_item.hburst==5)
    //      length=8;
    //   else  if (seq_item.hburst==7)
    //       length=16;
    for(int i=0; i<length;i++)
      begin
        if(i==0)
          begin
            clk_task();

            intf1.haddr=seq_item.haddr;
            intf1.hburst=seq_item.hburst;
            intf1.hsize=seq_item.hsize;
            intf1.htrans=2'b10;
            intf1.hwrite=seq_item.hwrite;

            clk_task();

            intf1.hwdata=seq_item.hwdata[i];
            intf1.haddr=seq_item.haddr+(2**seq_item.hsize*(i+1));
            intf1.htrans=2'b11;
          end
        else if(i!==length-1)
          begin
            clk_task();
            intf1.hwdata=seq_item.hwdata[i];
            intf1.haddr=seq_item.haddr+(2**seq_item.hsize*(i+1));
            intf1.htrans=2'b11;
          end
        else
          begin
            clk_task();
            intf1.hwdata=seq_item.hwdata[i];
            intf1.htrans=2'b00;

          end
        `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon write hwdata=%0p",intf1.hwdata),UVM_LOW)
        `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon write haddr=%0p", intf1.haddr),UVM_LOW)
        `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon write htrans=%0p",intf1.htrans),UVM_LOW)
        `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon write hsize=%0p", intf1.hsize),UVM_LOW)
        `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon write hwrite=%0p",intf1.hwrite),UVM_LOW)
        `uvm_info(get_type_name(), "------------------------------------------------------------", UVM_NONE)
      end
  endtask:ahb_write1

  task ahb_read1(ahb_sequence_item seq_item);
    //     if(seq_item.hburst==0)
    //       length=1;
    //     else if (seq_item.hburst==1)
    //       length=2;
    if(seq_item.hburst==3)
      length=4;
    //     else if(seq_item.hburst==5)
    //       length=8;
    //     else if(seq_item.hburst==7)
    //       length=16;
    for(int i=0;i<length;i++)
      begin
        if(i==0)
          begin
            clk_task();
            intf1.haddr=seq_item.haddr;
            intf1.hburst=seq_item.hburst;
            intf1.hsize=seq_item.hsize;
            intf1.htrans=2'b10;
            intf1.hwrite=seq_item.hwrite;
            clk_task();
            intf1.haddr=seq_item.haddr+(2**seq_item.hsize*(i+1));
            intf1.htrans=2'b11;

          end
        else if(i!==length-1)
          begin
            clk_task();
            intf1.haddr=seq_item.haddr+(2**seq_item.hsize*(i+1));
            intf1.htrans=2'b11;
          end
        else
          begin
            clk_task();
            intf1.htrans=2'b00;
            clk_task();
            `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon read hwdata=%0p",intf1.hwdata),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon read haddr=%0p", intf1.haddr),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon read htrans=%0p",intf1.htrans),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon read hsize=%0p", intf1.hsize),UVM_LOW)
            `uvm_info(get_full_name(),$sformatf(" AHB interface drv_mon read hwrite=%0p",intf1.hwrite),UVM_LOW)
            `uvm_info(get_type_name(), "-------------------------------------------------------", UVM_NONE)
          end
      end
  endtask
endclass