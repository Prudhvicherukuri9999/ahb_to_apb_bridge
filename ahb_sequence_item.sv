class ahb_sequence_item extends uvm_sequence_item;
  // `uvm_object_utils(ahb_sequence_item)
  rand bit[31:0] haddr;
  rand bit[31:0] hwdata[];
  rand bit[2:0] hburst;
  rand bit[2:0] hsize;
  rand bit hwrite;
  bit[31:0] hrdata[];
  bit[1:0] htrans;


//   `uvm_object_utils_begin(ahb_sequence_item)
//   `uvm_field_int(haddr,UVM_ALL_ON)
//   `uvm_field_int(hwdata,UVM_ALL_ON)
//   `uvm_field_int(hburst,UVM_ALL_ON)
//   `uvm_field_int(hsize,UVM_ALL_ON)
//   `uvm_field_array_int(hwrite,UVM_ALL_ON)
//   `uvm_field_array_int(hrdata,UVM_ALL_ON)
//   `uvm_field_int(htrans,UVM_ALL_ON)
//   `uvm_object_utils_end
  
  
  
   `uvm_object_utils_begin(ahb_sequence_item)
    `uvm_field_int(haddr, UVM_ALL_ON)
    //`uvm_field_array(hwdata, UVM_ALL_ON)
    `uvm_field_int(hburst, UVM_ALL_ON)
    `uvm_field_int(hsize, UVM_ALL_ON)
    `uvm_field_int(hwrite, UVM_ALL_ON)
   // `uvm_field_aa_int(hrdata, UVM_ALL_ON)
    `uvm_field_int(htrans, UVM_ALL_ON)
  `uvm_object_utils_end
  function new(string name="ahb_sequence_item");
    super.new(name);
  endfunction

  constraint c_con1{ haddr inside{[0:255]};//1kb adderss boundary
                    hburst inside{0,1,3,5,7}; //burst only for single(0) ,incr(1),incr4(3),incr8(5),incr16(7)
                    hsize inside{0,1,2};//size byte(0),halfword(1),word(2)
                   }

  constraint c_con2{
    if(hsize==0)//if hsize is equal to zero address should be increased by 1
      haddr%1==0;
    else if(hsize==1)//if hsize is equal to one address should be increased by 2
      haddr%2==0;
    else if (hsize==2)//if hsize is equal to two address should be increased by 4
      haddr%4==0;
  }

  constraint c_con3{ hburst==0 <->hwdata.size==1;
                    hburst==1 <->hwdata.size==2;
                    hburst==3 <->hwdata.size==4;
                    hburst==5 <->hwdata.size==8;
                    hburst==7 <->hwdata.size==16;
                   }
  constraint c_con4{
    if(hsize==0)
      foreach(hwdata[i])
        hwdata[i] inside{[0:99]};
    else if(hsize==1)
      foreach(hwdata[i])
        hwdata[i] inside{[100:199]};
    else if(hsize==2)
      foreach(hwdata[i])
        hwdata[i] inside{[200:255]};}

endclass



