`ifndef KEI_I2C_MASTER_RX_OVER_INTR_VIRT_SEQ_SV
`define KEI_I2C_MASTER_RX_OVER_INTR_VIRT_SEQ_SV

class kei_i2c_master_rx_over_intr_virt_seq extends kei_i2c_base_virtual_sequence;

  `uvm_object_utils(kei_i2c_master_rx_over_intr_virt_seq)

  function new (string name = "kei_i2c_master_rx_over_intr_virt_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "=====================STARTED=====================", UVM_LOW)
    super.body();
    vif.wait_rstn_release();
    vif.wait_apb(10);
    
    /*
    RX_OVER中断发生在rx_fifo已满，但继续有数据试图被接收时，该数据会被遗弃
    */
    
    `uvm_do_on_with(apb_cfg_seq,
                    p_sequencer.apb_mst_sqr,
                    {SPEED == 2;
                    IC_10BITADDR_MASTER == 0;
                    IC_TAR == `KEI_VIP_I2C_SLAVE0_ADDRESS;
                    IC_FS_SCL_HCNT == 200;
                    IC_FS_SCL_LCNT == 200;
                    ENABLE == 1;})
                    
		rgm.IC_RX_TL.RX_TL.set(5);
    rgm.IC_RX_TL.update(status);
    
    rgm.IC_INTR_MASK.M_RX_FULL.set(1);
    rgm.IC_INTR_MASK.update(status);
    
    fork
			`uvm_do_on_with(apb_noread_packet_seq,
											p_sequencer.apb_mst_sqr,
											{packet.size() == 8;})
		
			`uvm_do_on_with(i2c_slv_read_resp_seq,
											p_sequencer.i2c_slv_sqr,
											{packet.size() == 8;
											packet[0] == 8'b00000001;
											packet[1] == 8'b00000010;
											packet[2] == 8'b00000100;
											packet[3] == 8'b00001000;
											packet[4] == 8'b00010000;
											packet[5] == 8'b00100000;
											packet[6] == 8'b01000000;
											packet[7] == 8'b10000000;})
		join
    
    rgm.IC_STATUS.mirror(status);
    rgm.IC_DATA_CMD.mirror(status);  
    
    fork
      `uvm_do_on_with(apb_noread_packet_seq,
											p_sequencer.apb_mst_sqr,
											{packet.size() == 8;})
		
			`uvm_do_on_with(i2c_slv_read_resp_seq,
											p_sequencer.i2c_slv_sqr,
											{packet.size() == 8;
											packet[0] == 8'b00010001;
											packet[1] == 8'b00010010;
											packet[2] == 8'b00010100;
											packet[3] == 8'b00011000;
											packet[4] == 8'b10010001;
											packet[5] == 8'b00110000;
											packet[6] == 8'b01010000;
											packet[7] == 8'b10010000;})
    join_none
    
    `uvm_do_on_with(apb_intr_wait_seq,p_sequencer.apb_mst_sqr,{intr_id == IC_RX_OVER_INTR_ID;})
    
    if(vif.get_intr(IC_RX_OVER_INTR_ID) !== 1'b1)
      `uvm_error("INTRERR", "interrupt output IC_RX_OVER_INTR_ID is not high")
    else
      `uvm_info("INTRERR", "interrupt output IC_RX_OVER_INTR_ID is high", UVM_LOW)
		
    `uvm_do_on_with(apb_intr_clear_seq,p_sequencer.apb_mst_sqr,{intr_id == IC_RX_OVER_INTR_ID;})
    
    #10us;

    `uvm_info(get_type_name(), "=====================FINISHED=====================", UVM_LOW)
  endtask

endclass
`endif // KEI_I2C_MASTER_RX_OVER_INTR_VIRT_SEQ_SV
