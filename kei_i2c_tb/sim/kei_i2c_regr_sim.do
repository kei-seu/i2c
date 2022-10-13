#======================================#
# TCL script for a mini regression     #
#======================================#
onbreak resume
onerror resume

# set environment variables
setenv DUT_SRC ../../kei_dw_apb_i2c
setenv TB_SRC .

set INCDIR "+incdir+../../kei_dw_apb_i2c/src \
					  +incdir+../agents/kei_vip_apb3 \
					  +incdir+../agents/kei_vip_i2c \
					  +incdir+../cfg \
					  +incdir+../cov \
					  +incdir+../reg \
					  +incdir+../env \
					  +incdir+../seq_lib \
					  +incdir+../seq_lib/elem_seqs \
					  +incdir+../seq_lib/user_elem_seqs \
					  +incdir+../seq_lib/user_virt_seqs \
					  +incdir+../tests/user_tests \
					  +incdir+../tests "

set VCOMP "vlog -cover bst -timescale=1ns/1ps -l comp.log $INCDIR"


# clean the environment and remove trash files
set delfiles [glob work *.log *.ucdb sim.list]

file delete -force {*}$delfiles

# compile the design and dut with a filelist
vlib work
eval $VCOMP -f  kei_i2c.flist
eval $VCOMP -sv ../agents/kei_vip_apb3/kei_vip_apb_if.sv 
eval $VCOMP -sv ../agents/kei_vip_apb3/kei_vip_apb_pkg.sv 
eval $VCOMP -sv ../agents/kei_vip_i2c/kei_vip_i2c_if.sv 
eval $VCOMP -sv ../agents/kei_vip_i2c/kei_vip_i2c_pkg.sv 
eval $VCOMP -sv ../env/kei_i2c_pkg.sv 
eval $VCOMP -sv ../tb/kei_i2c_if.sv 
eval $VCOMP -sv ../tb/kei_i2c_tb.sv 

# call a UVM test
#set TEST kei_i2c_quick_reg_access_test
#set VERB UVM_HIGH
#set SEED 0
#set SEED [expr int(rand() * 100)]
#vsim work.kei_i2c_tb -classdebug -sv_seed $SEED +UVM_TESTNAME=$TEST +UVM_VERBOSITY=$VERB -l sim.log

# prepare simrun folder
set timetag [clock format [clock seconds] -format "%Y%b%d-%H_%M"]
file mkdir regr_ucdb_${timetag}

# simulate with specific testname sequentially
set TestSets {  {kei_i2c_reg_hw_reset_test 1} \
                {kei_i2c_reg_bit_bash_test 1} \
                {kei_i2c_reg_access_test 1} \
                {kei_i2c_quick_reg_access_test 1} \
                {kei_i2c_master_directed_write_packet_test 1} \
                {kei_i2c_master_directed_read_packet_test 1} \
                {kei_i2c_master_directed_interrupt_test 1} \ 
              }

foreach testset $TestSets {
  set testname [lindex $testset 0]
  set LoopNum [lindex $testset 1]
  for {set loop 0} {$loop < $LoopNum} {incr loop} {
    set seed [expr int(rand() * 100)]
    echo simulating $testname
    echo $seed +UVM_TESTNAME=$testname -l regr_ucdb_${timetag}/run_${testname}_${seed}.log
    vsim -onfinish stop -cover -sv_seed $seed \
         +UVM_TESTNAME=$testname -l regr_ucdb_${timetag}/run_${testname}_${seed}.log work.kei_i2c_tb
    run -all
    coverage save regr_ucdb_${timetag}/${testname}_${seed}.ucdb
    quit -sim
  }
}

# merge the ucdb per test
#vcover merge -testassociated regr_ucdb_${timetag}/regr_${timetag}.ucdb ../doc/questa_vplan.ucdb {*}[glob regr_ucdb_${timetag}/*.ucdb]
vcover merge -testassociated regr_ucdb_${timetag}/regr_${timetag}.ucdb ../doc/questa10.6c_vplan.ucdb {*}[glob regr_ucdb_${timetag}/*.ucdb]

quit -f

