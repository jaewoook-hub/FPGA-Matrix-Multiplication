setenv LMC_TIMEUNIT -9
vlib work
vcom -work work "matmul.vhd"
vcom -work work "bram.vhd"
vcom -work work "matmul_top.vhd"
vcom -work work "matmul_tb.vhd"
vcom -work work "bram_block.vhd"
vcom -work work "constants.vhd"
vsim +notimingchecks -L work work.matmul_tb -wlf matmul_sim.wlf

add wave -noupdate -group matmul_tb
add wave -noupdate -group matmul_tb -radix hexadecimal /matmul_tb/*
add wave -noupdate -group matmul_tb/matmul_top_inst
add wave -noupdate -group matmul_tb/matmul_top_inst -radix hexadecimal /matmul_tb/matmul_top_inst/*
add wave -noupdate -group matmul_tb/matmul_top_inst/matmul_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/matmul_inst -radix hexadecimal /matmul_tb/matmul_top_inst/matmul_inst/*
add wave -noupdate -group matmul_tb/matmul_top_inst/mat_1_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/mat_1_inst -radix hexadecimal /matmul_tb/matmul_top_inst/mat_1_inst/*
add wave -noupdate -group matmul_tb/matmul_top_inst/mat_2_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/mat_2_inst -radix hexadecimal /matmul_tb/matmul_top_inst/mat_2_inst/*
add wave -noupdate -group matmul_tb/matmul_top_inst/mat_3_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/mat_3_inst -radix hexadecimal /matmul_tb/matmul_top_inst/mat_3_inst/*

run -all