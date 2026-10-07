# =============================================================================
# sim_complet.do : simulation du decodeur complet (parties 3 a 6)
#
# Le banc de test tb_DecodeurIR.vhd envoie de vrais messages NEC (touche '5',
# code repetitif, touche 'A') et verifie automatiquement la commande decodee.
# Resultat dans la console : "OK touche 5 : Command = 0xFA05" etc.
#
# lancement depuis ce dossier :  vsim -do sim_complet.do
# (environ 215 ms de temps simule : patienter quelques dizaines de secondes)
# =============================================================================
set COMPARATEUR ../Comp_MaxValue.vhd
do compiler.do
vcom -93 -work work tb_DecodeurIR.vhd

vsim -t 1ps work.tb_DecodeurIR

add wave -divider "telecommande (patte Y15)"
add wave -label IR_RX             sim:/tb_DecodeurIR/IR_RX
add wave -divider "partie 3 : echantillonnage"
add wave -label SamplingEdge      sim:/tb_DecodeurIR/SamplingEdge
add wave -divider "partie 4 : preambule"
add wave -label StartEvent        sim:/tb_DecodeurIR/StartEvent
add wave -label LEDG0             sim:/tb_DecodeurIR/LEDG0
add wave -divider "partie 5 : machine d'etats"
add wave -label AddressInProgress sim:/tb_DecodeurIR/AddressInProgress
add wave -label CommandInProgress sim:/tb_DecodeurIR/CommandInProgress
add wave -divider "partie 6 : commande (LEDR)"
add wave -label {Command[15..0]} -radix hexadecimal sim:/tb_DecodeurIR/Command

run -all
wave zoom full
