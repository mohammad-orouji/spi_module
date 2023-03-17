
####################################################################################
###	        		Clock and other signals pin assignment			             ###
####################################################################################
set_property PACKAGE_PIN U14 [get_ports CLK_12m]
set_property IOSTANDARD LVCMOS18 [get_ports CLK_12m]

#####################Clock Timing Constraint#####################
create_clock -period 83.333 -name CLK_12m [get_ports CLK_12m]

#LED lock
# set_property PACKAGE_PIN R14 [get_ports {led_o[0]}]
# set_property PACKAGE_PIN Y16 [get_ports {led_o[1]}]
# set_property PACKAGE_PIN Y17 [get_ports {led_o[2]}]
# set_property IOSTANDARD LVCMOS25 [get_ports {led_o[*]}]

#dip_swich
# set_property PACKAGE_PIN R19 [get_ports {push_button_i[0]} ]
# set_property PACKAGE_PIN T19 [get_ports {push_button_i[1]} ]
# set_property PACKAGE_PIN G14 [get_ports {push_button_i[2]} ]
# set_property PACKAGE_PIN J15 [get_ports {push_button_i[3]} ]
# set_property IOSTANDARD LVCMOS25 [get_ports {push_button_i[*]} ]
####################################################################################
###	        		END Clock and other signals pin assignment			         ###
####################################################################################

