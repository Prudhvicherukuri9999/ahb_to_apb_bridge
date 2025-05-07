class ahb_apb_test extends uvm_test;
  `uvm_component_utils(ahb_apb_test)

  ahb_apb_environment env;
  ahb_sequence seq;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    env=ahb_apb_environment::type_id::create("env",this);
    seq=ahb_sequence::type_id::create("seq",this);
    uvm_top.set_report_verbosity_level_hier(UVM_DEBUG);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq.start(env.ahb_agt.ahb_sqr);
    #100;
    phase.drop_objection(this);
  endtask
  

  virtual function void end_of_elaboration();
    print();
  endfunction
  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);

    svr = uvm_report_server::get_server();
    if(svr.get_severity_count(UVM_FATAL)+svr.get_severity_count(UVM_ERROR)>0) begin

      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----            TEST FAIL          ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    else begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
  endfunction 



endclass
