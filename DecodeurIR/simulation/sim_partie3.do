# =============================================================================
# sim_partie3.do : simulation du paragraphe 3.2 (verification par simulation)
#
# Le comparateur Comp_MaxValue est regle sur une faible valeur (4) au lieu de
# R-1 : le compteur parcourt 0,1,2,3,4 -> un cycle complet = 5 x 20 ns.
# On observe l'horloge MainClk et la sortie du comparateur SamplingClk
# (signal d'echantillonnage), comme sur la figure de la page 10 du sujet.
#
# lancement depuis ce dossier :  vsim -do sim_partie3.do
# =============================================================================
set COMPARATEUR partie3/Comp_MaxValue.vhd
do compiler.do

vsim -t 1ps work.decodeurir

# horloge 50 MHz sur MainClk (equivalent de clic droit -> Clock... : periode 20 ns)
force -freeze sim:/decodeurir/MainClk 1 0, 0 {10 ns} -repeat {20 ns}
force -freeze sim:/decodeurir/IR_RX 1 0

add wave -position end sim:/decodeurir/MainClk
add wave -position end sim:/decodeurir/SamplingClk

run {400 ns}
wave zoom full
