
`uvm_analysis_imp_decl(_seq1)
`uvm_analysis_imp_decl(_seq2)

class ahb_apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ahb_apb_scoreboard)

  ahb_sequence_item a;
  apb_sequence_item b;

  uvm_analysis_imp_seq1#(ahb_sequence_item, ahb_apb_scoreboard) seq1_imp;
  uvm_analysis_imp_seq2#(apb_sequence_item, ahb_apb_scoreboard) seq2_imp;

  ahb_sequence_item s1[$];
  apb_sequence_item s2[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq1_imp = new("seq1_imp", this);
    seq2_imp = new("seq2_imp", this);
    `uvm_info("SCOREBOARD", "Scoreboard Build Phase Completed", UVM_LOW)
  endfunction

  function void write_seq1(ahb_sequence_item seq_item);
    if (seq_item != null) begin
      s1.push_front(seq_item);
      `uvm_info("SCOREBOARD", $sformatf("Received AHB transaction: haddr=0x%0h", seq_item.haddr), UVM_MEDIUM)
    end
  endfunction

  function void write_seq2(apb_sequence_item seq_item);
    if (seq_item != null) begin
      s2.push_front(seq_item);
      `uvm_info("SCOREBOARD", $sformatf("Received APB transaction: paddr=0x%0h", seq_item.paddr), UVM_MEDIUM)
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      wait (s1.size() > 0 && s2.size() > 0);

      a = s1.pop_back();
      b = s2.pop_back();

      if (a == null || b == null) begin
        `uvm_error("SCOREBOARD", "Null transaction received in scoreboard")
        continue;
      end

      // Address Comparison
      if (a.haddr == b.paddr) begin
        `uvm_info("SCOREBOARD", "AHB address matched with APB address", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Address match: AHB=0x%0h, APB=0x%0h", a.haddr, b.paddr),UVM_LOW)
      end else begin
        `uvm_error("SCOREBOARD", $sformatf("Address mismatch: AHB=0x%0h, APB=0x%0h", a.haddr, b.paddr))
      end

      // Write Data Comparison
      if (a.hwrite) begin
        if (a.hwdata.size() != b.pwdata.size()) begin
          `uvm_error("SCOREBOARD", "Write data size mismatch between AHB and APB")
        end else begin
          foreach (b.pwdata[i]) begin
            `uvm_info("SCOREBOARD", $sformatf("Comparing: hwdata[%0d]=%0h, pwdata[%0d]=%0h",
                                              i, a.hwdata[i], i, b.pwdata[i]), UVM_LOW)
            if (a.hwdata[i] != b.pwdata[i]) begin
              `uvm_error("SCOREBOARD", $sformatf("Write data mismatch at index %0d", i))
              `uvm_info("SCOREBOARD", $sformatf("Comparing AHB hwdata with APB pwdata at address 0x%0h", b.paddr), UVM_LOW);
              if (a.hwdata != b.pwdata) begin
                `uvm_error("SCOREBOARD", $sformatf("Write data mismatch at address"));
              end
            end
          end
        end
      end

      // Read Data Comparison
      if (!a.hwrite) begin
        if (a.hrdata.size() != b.prdata.size()) begin
          `uvm_error("SCOREBOARD", "Read data size mismatch between AHB and APB")
        end else begin
          foreach (a.hrdata[i]) begin
            `uvm_info("SCOREBOARD", $sformatf("Comparing: hrdata[%0d]=%0h, prdata[%0d]=%0h",
                                              i, a.hrdata[i], i, b.prdata[i]), UVM_LOW)
            if (a.hrdata[i] != b.prdata[i]) begin
              `uvm_error("SCOREBOARD", $sformatf("Read data mismatch at index %0d", i))
            end
          end
        end
      end

    end
  endtask

endclass
