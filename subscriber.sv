`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_apb)

class my_coverage extends uvm_component;
  `uvm_component_utils(my_coverage)

  // Analysis implementation ports 
  uvm_analysis_imp_ahb #(ahb_sequence_item, my_coverage) ahb_imp; 
  uvm_analysis_imp_apb #(apb_sequence_item, my_coverage) apb_imp;
  ahb_sequence_item seq_item; 
  apb_sequence_item apb_item;
//=========================================================================================================================================
  // Covergroup for AHB transactions 
  covergroup ahb_cg; 
    option.per_instance = 1;

    haddr: coverpoint seq_item.haddr {
     									 bins low_addr = {[0:63]};
      								   //bins mid_addr[] = {[64:127]};  // Middle 256 bytes
      								   //bins high_addr[] = {[128:255]};// Upper 256 bytes
                                     }

    hburst: coverpoint seq_item.hburst {
     								   //bins single = {0};
      								   //bins incr = {1};
                                         bins incr4 = {3};
                                       //bins incr8 = {5};
                                       //bins incr16 = {7};
                                       }

    hsize: coverpoint seq_item.hsize {
                                      // bins BYTE = {0};
                                      // bins HWORD = {1};
                                         bins WORD = {2};
                                     }

    hwrite: coverpoint seq_item.hwrite {
                                         bins read = {0};
                                         bins write = {1};
                                       }

    hwdata: coverpoint seq_item.hwdata[0] 
                                        iff (seq_item.hwrite) 
                                       {
                                         //bins low_data = {[0:99]};
                                         //bins mid_data[] = {[100:199]}; // Mid range for halfword
                                           bins high_data = {[200:255]};// High range for word
                                        }

    hrdata: coverpoint seq_item.hrdata[0] 
                                        iff (!seq_item.hwrite) 
                                       {
                                         // bins low_data[] = {[0:99]};
                                        //  bins mid_data[] = {[100:199]};
                                            bins high_data = {[200:255]};
                                        }

    // Cross coverage
    addr_size: cross haddr, hsize;
    burst_size: cross hburst, hsize;
    addr_write: cross haddr, hwrite;

  endgroup
//===========================================================================================================================================
  // Covergroup for APB transactions 
  covergroup apb_cg; 
    option.per_instance = 1;

    paddr: coverpoint apb_item.paddr {
                                        bins low_addr = {[0:63]};
                                    //  bins mid_addr[] = {[64:127]};
                                    //  bins high_addr[] = {[128:255]};
                                     }

    pburst: coverpoint apb_item.pburst {
                                          bins single = {0};
                                          bins incr4 = {3};
                                       }

    pwrite: coverpoint apb_item.pwrite {
                                          bins read = {0};
                                          bins write = {1};
                                       }

    pwdata: coverpoint apb_item.pwdata[0] 
                                         iff (apb_item.pwrite) 
                                      {
                                       // bins low_data[] = {[0:99]};
                                      //  bins mid_data[] = {[100:199]};
                                          bins high_data = {[200:255]};
                                      }

    prdata: coverpoint apb_item.prdata[0] 
                                        iff (!apb_item.pwrite) 
                                      {
                                       // bins low_data[] = {[0:99]};
                                       // bins mid_data[] = {[100:199]};
                                          bins high_data = {[200:255]};
                                       }

    // Cross coverage
    addr_write: cross paddr, pwrite;
    burst_write: cross pburst, pwrite;

  endgroup
//===============================================================================================================================================
  // Cross coverage between AHB and APB addresses
  covergroup  addr_mapping_cg;
    option.per_instance = 1;

    ahb_addr: coverpoint seq_item.haddr {
                                           bins low_addr = {[0:63]};
                                        // bins mid_addr[] = {[64:127]};
                                        // bins high_addr[] = {[128:255]};
                                        }

    apb_addr: coverpoint apb_item.paddr {
                                           bins low_addr = {[0:63]};
                                        // bins mid_addr[] = {[64:127]};
                                        // bins high_addr[] = {[128:255]};
                                        }

    addr_cross: cross ahb_addr, apb_addr;
  endgroup

  function new(string name, uvm_component parent); 
    super.new(name, parent); 
    ahb_cg = new(); 
    apb_cg = new(); 
    addr_mapping_cg = new(); 
    ahb_imp = new("ahb_imp", this); 
    apb_imp = new("apb_imp", this); 
  endfunction

  function void build_phase(uvm_phase phase); 
    super.build_phase(phase); 
  endfunction

  // Write function for AHB transactions
  function void write_ahb(ahb_sequence_item t);
    seq_item = t;
    ahb_cg.sample(); 
    if (apb_item != null) 
      begin 
        addr_mapping_cg.sample(); 
      end 
    `uvm_info("AHB_COVERAGE", $sformatf("AHB coverage sampled: haddr=0x%0h", t.haddr), UVM_MEDIUM) 
    `uvm_info("AHB_COVERAGE", $sformatf("AHB coverage percentage=%0f",$get_coverage()),UVM_LOW)
  endfunction 

  // Write function for APB transactions
  function void write_apb(apb_sequence_item t); 
    apb_item = t; 
    apb_cg.sample(); 
    if (seq_item != null) 
      begin 
        addr_mapping_cg.sample(); 
      end 
		`uvm_info("APB_COVERAGE", $sformatf("APB coverage sampled: paddr=0x%0h", t.paddr), UVM_MEDIUM)
        `uvm_info("APB_COVERAGE", $sformatf("ApB coverage percentage=%0f",$get_coverage()),UVM_LOW)

  endfunction 
endclass