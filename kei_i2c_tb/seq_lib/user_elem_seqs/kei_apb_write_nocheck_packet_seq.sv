
`ifndef KEI_APB_WRITE_NOCHECK_PACKET_SEQ_SV
`define KEI_APB_WRITE_NOCHECK_PACKET_SEQ_SV

class kei_apb_write_nocheck_packet_seq extends kei_apb_base_sequence;

  `uvm_object_utils(kei_apb_write_nocheck_packet_seq)

  constraint def_cstr {
    soft packet.size() == 1;
  }

  function new (string name = "kei_apb_write_nocheck_packet_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("body", "Entering...", UVM_HIGH)
    super.body();

    foreach(packet[i]) begin
      rgm.IC_DATA_CMD.DAT.set(packet[i]);
      rgm.IC_DATA_CMD.CMD.set(RGM_WRITE); 
      // Use Frontdoor write instead of update() method to take 
      // explicit write and avoid 'no-action' if mirror value 
      // eqauls desired value
      rgm.IC_DATA_CMD.write(status, rgm.IC_DATA_CMD.get());
    end

    `uvm_info("body", "Exiting...", UVM_HIGH)
  endtask

endclass

`endif // KEI_APB_WRITE_NOCHECK_PACKET_SEQ_SV
