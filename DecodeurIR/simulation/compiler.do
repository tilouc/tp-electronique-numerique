# =============================================================================
# compiler.do : compilation des sources du projet pour ModelSim / Questa
# (appele par sim_partie3.do et sim_complet.do, ne pas lancer seul)
# =============================================================================
transcript on

if {![info exists COMPARATEUR]} {
    set COMPARATEUR ../Comp_MaxValue.vhd
}

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# Repertoire des modeles de simulation de Quartus (bibliotheque lpm)
proc trouver_sim_lib {} {
    global env
    set candidats {}
    if {[info exists env(QUARTUS_ROOTDIR)]} {
        lappend candidats [file join $env(QUARTUS_ROOTDIR) eda sim_lib]
    }
    if {[info exists env(MODEL_TECH)]} {
        lappend candidats [file normalize [file join $env(MODEL_TECH) .. .. quartus eda sim_lib]]
    }
    foreach c $candidats {
        if {[file exists [file join $c 220model.vhd]]} {
            return $c
        }
    }
    return ""
}

# La bibliotheque lpm est precompilee dans ModelSim-Intel et Questa-Intel.
# Si elle n'est pas trouvee, on la compile a partir des sources de Quartus.
if {[catch {vcom -93 -work work ../Counter_Nbits.vhd}]} {
    set sim_lib [trouver_sim_lib]
    if {$sim_lib eq ""} {
        error "bibliotheque lpm introuvable : lancez la simulation avec ../../run.sh"
    }
    echo "compilation de la bibliotheque lpm depuis $sim_lib"
    vlib lpm_local
    vmap lpm lpm_local
    vcom -93 -work lpm [file join $sim_lib 220pack.vhd] [file join $sim_lib 220model.vhd]
    vcom -93 -work work ../Counter_Nbits.vhd
}

# composants generes avec l'IP Catalog (MegaWizard)
vcom -93 -work work $COMPARATEUR
vcom -93 -work work ../ShiftReg24bits.vhd
vcom -93 -work work ../CompLeadPulse.vhd
vcom -93 -work work ../CountMod48.vhd
vcom -93 -work work ../CompareTo47.vhd
vcom -93 -work work ../Count2bits.vhd
vcom -93 -work work ../ShiftReg16bits.vhd
# machine d'etats generee par le State Machine Editor
vcom -93 -work work ../FrameDecoder.vhd
# schema principal (traduit en VHDL)
vcom -93 -work work DecodeurIR_rtl.vhd
