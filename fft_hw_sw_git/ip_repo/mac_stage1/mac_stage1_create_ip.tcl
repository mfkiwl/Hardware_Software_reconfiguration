create_ip -name xbip_multadd -vendor xilinx.com -library ip -version 3.0 -module_name mac_stage1
set_property -dict [list CONFIG.Component_Name {mac_stage1} CONFIG.c_a_width {32} CONFIG.c_b_width {32} CONFIG.c_c_width {64} CONFIG.c_out_high {65} CONFIG.c_ab_latency {0} CONFIG.c_c_latency {0} CONFIG.c_out_low {0}] [get_ips mac_stage1]