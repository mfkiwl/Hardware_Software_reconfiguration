// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Fri Dec 10 16:17:02 2021
// Host        : DESKTOP-TMARPD0 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top main_design_blk_mem_gen_0_0 -prefix
//               main_design_blk_mem_gen_0_0_ main_design_blk_mem_gen_0_0_stub.v
// Design      : main_design_blk_mem_gen_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *)
module main_design_blk_mem_gen_0_0(clka, ena, wea, addra, dina, douta, clkb, enb, web, addrb, 
  dinb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[11:0],dina[63:0],douta[63:0],clkb,enb,web[0:0],addrb[11:0],dinb[63:0],doutb[63:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [11:0]addra;
  input [63:0]dina;
  output [63:0]douta;
  input clkb;
  input enb;
  input [0:0]web;
  input [11:0]addrb;
  input [63:0]dinb;
  output [63:0]doutb;
endmodule
