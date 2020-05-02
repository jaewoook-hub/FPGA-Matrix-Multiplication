setenv LMC_TIMEUNIT -9
vlib work
vcom -work work "matmul.vhd"
vcom -work work "fifo.vhd"
vcom -work work "mat_mul_top.vhd"
vcom -work work "matmul_tb.vhd"
vsim +notimingchecks -L work work.matmul_tb -wlf matmul_sim.wlf

add wave -noupdate -group matmul_tb
add wave -noupdate -group matmul_tb -radix hexadecimal /matmul_tb/*
add wave -noupdate -group matmul_tb/mat_mul_top_inst
add wave -noupdate -group matmul_tb/mat_mul_top_inst -radix hexadecimal /matmul_tb/mat_mul_top_inst/*
add wave -noupdate -group matmul_tb/mat_mul_top_inst/matmul_inst
add wave -noupdate -group matmul_tb/mat_mul_top_inst/matmul_inst -radix hexadecimal /matmul_tb/mat_mul_top_inst/matmul_inst/*
add wave -noupdate -group matmul_tb/mat_mul_top_inst/x_inst
add wave -noupdate -group matmul_tb/mat_mul_top_inst/x_inst -radix hexadecimal /matmul_tb/mat_mul_top_inst/x_inst/*
add wave -noupdate -group matmul_tb/mat_mul_top_inst/y_inst
add wave -noupdate -group matmul_tb/mat_mul_top_inst/y_inst	 -radix hexadecimal /matmul_tb/mat_mul_top_inst/y_inst/*
add wave -noupdate -group matmul_tb/mat_mul_top_inst/z_inst
add wave -noupdate -group matmul_tb/mat_mul_top_inst/z_inst -radix hexadecimal /matmul_tb/mat_mul_top_inst/z_inst/*

run -all