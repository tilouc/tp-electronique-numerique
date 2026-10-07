# contrainte de temps : oscillateur a quartz 50 MHz (patte Y2) -> periode 20 ns
create_clock -name MainClk -period 20.000 [get_ports {MainClk}]
derive_clock_uncertainty
