create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {main_clk_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLOCK_50}]

# Constrain the input I/O path
set_input_delay -clock {main_clk_50} -max 3 [all_inputs]
set_input_delay -clock {main_clk_50} -min 2 [all_inputs]

# Constrain the output I/O path
set_output_delay -clock {main_clk_50} 2 [all_outputs]
