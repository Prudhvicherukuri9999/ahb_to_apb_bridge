class ahb_apb_environment extends uvm_env;
  `uvm_component_utils(ahb_apb_environment)
  ahb_agent ahb_agt;
  apb_agent apb_agt;
  ahb_apb_scoreboard sb;
  my_coverage cov;
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    ahb_agt=ahb_agent::type_id::create("ahb_agt",this);
    apb_agt=apb_agent::type_id::create("apb_agt",this);
    sb=ahb_apb_scoreboard::type_id::create("sb",this);
    cov=my_coverage::type_id::create("cov",this);
  endfunction


  function void connect_phase (uvm_phase phase);
    ahb_agt.ahb_mon.seq1_put.connect(sb.seq1_imp);
    apb_agt.apb_mon.seq2_put.connect(sb.seq2_imp);
    ahb_agt.ahb_mon.seq1_put.connect(cov.ahb_imp);
    apb_agt.apb_mon.seq2_put.connect(cov.apb_imp);
  endfunction

endclass