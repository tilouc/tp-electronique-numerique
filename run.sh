#!/usr/bin/env bash
# =============================================================================
# run.sh : tp fpga "decodeur infrarouge" (carte terasic de2-115, quartus)
#
#   ./run.sh               programme la carte (fichier .sof deja compile)
#   ./run.sh compiler      recompile le projet quartus puis programme la carte
#   ./run.sh ouvrir        ouvre le projet dans quartus (schema, machine d'etats)
#   ./run.sh simulation    simulation complete (modelsim / questa, sinon ghdl)
#   ./run.sh simulation3   simulation du paragraphe 3.2 (diviseur de frequence)
#   ./run.sh usb           autorise l'acces au cable usb-blaster (une seule fois)
# =============================================================================
set -u

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJET="$ICI/DecodeurIR"
SOF="output_files/DecodeurIR.sof"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[erreur]\033[0m %s\n' "$*" >&2; }

# -----------------------------------------------------------------------------
# recherche de quartus (PATH, QUARTUS_ROOTDIR ou dossiers d'installation)
# -----------------------------------------------------------------------------
QBIN=""
trouver_quartus() {
    [ -n "$QBIN" ] && return 0
    if command -v quartus_sh >/dev/null 2>&1; then
        QBIN="$(dirname "$(command -v quartus_sh)")"
    else
        local c
        for c in ${QUARTUS_ROOTDIR:+"$QUARTUS_ROOTDIR/bin"} $(ls -d \
                "$HOME"/intelFPGA_lite/*/quartus/bin "$HOME"/intelFPGA/*/quartus/bin \
                "$HOME"/altera_lite/*/quartus/bin "$HOME"/altera/*/quartus/bin \
                /opt/intelFPGA_lite/*/quartus/bin /opt/intelFPGA/*/quartus/bin \
                /opt/altera_lite/*/quartus/bin /opt/altera/*/quartus/bin \
                2>/dev/null | sort -V -r); do
            if [ -x "$c/quartus_sh" ]; then
                QBIN="$c"
                break
            fi
        done
    fi
    if [ -z "$QBIN" ]; then
        err "quartus introuvable."
        echo "installe quartus prime lite (voir readme.md), ou indique son dossier :"
        echo "  export QUARTUS_ROOTDIR=\$HOME/intelFPGA_lite/19.1/quartus"
        return 1
    fi
    export QUARTUS_ROOTDIR="$(dirname "$QBIN")"
    return 0
}

# -----------------------------------------------------------------------------
# acces au cable usb-blaster sous linux (regle udev + liste des composants jtag)
# -----------------------------------------------------------------------------
config_usb() {
    trouver_quartus || return 1
    info "configuration de l'acces usb-blaster (mot de passe administrateur demande)"
    sudo tee /etc/udev/rules.d/51-usbblaster.rules >/dev/null <<'EOF'
# USB-Blaster integre a la carte DE2-115 et USB-Blaster II
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    if [ -f "$QUARTUS_ROOTDIR/linux64/pgm_parts.txt" ]; then
        sudo mkdir -p /etc/jtagd
        sudo cp "$QUARTUS_ROOTDIR/linux64/pgm_parts.txt" /etc/jtagd/jtagd.pgm_parts
    fi
    killall jtagd >/dev/null 2>&1
    sleep 1
    ok "acces usb configure"
}

carte_branchee() {
    lsusb 2>/dev/null | grep -q -i -E "09fb:(6001|6002|6003|6010|6810)"
}

cable_jtag() {
    "$QBIN/quartus_pgm" -l 2>/dev/null | sed -n 's/^[0-9][0-9]*) //p' | head -n 1
}

# -----------------------------------------------------------------------------
# programmation du fpga
# -----------------------------------------------------------------------------
programmer() {
    trouver_quartus || return 1
    if [ ! -f "$PROJET/$SOF" ]; then
        info "pas encore de fichier $SOF : compilation"
        compiler_projet || return 1
    fi
    if [ ! -f /etc/udev/rules.d/51-usbblaster.rules ] && carte_branchee; then
        # premiere utilisation : linux doit autoriser l'acces au cable
        config_usb || return 1
    fi
    local cable
    cable="$(cable_jtag)"
    if [ -z "$cable" ] && carte_branchee; then
        # carte vue par linux mais inaccessible : on configure l'usb puis on reessaie
        config_usb || return 1
        cable="$(cable_jtag)"
    fi
    if [ -z "$cable" ]; then
        err "aucun cable usb-blaster detecte."
        echo "  - branche le cable usb sur le port 'USB BLASTER' de la carte (a gauche)"
        echo "  - allume la carte (bouton rouge) et mets le switch RUN/PROG sur RUN"
        echo "  - si la carte est deja branchee : ./run.sh usb, puis debranche/rebranche le cable"
        return 1
    fi
    info "programmation du fpga (cable : $cable)"
    if (cd "$PROJET" && "$QBIN/quartus_pgm" -c "$cable" -m JTAG -o "p;$SOF"); then
        ok "fpga programme !"
        echo
        echo "  appuie sur une touche de la telecommande (vise le recepteur ir de la carte) :"
        echo "  - les 4 leds vertes LEDG0..3 changent d'etat a chaque appui (partie 4)"
        echo "  - les leds rouges LEDR7..0 affichent le code de la touche (partie 6)"
        echo "    ex : touche 5 -> 0000 0101, touche A -> 0000 1111"
        echo "  - les leds rouges LEDR15..8 affichent son complement"
    else
        err "la programmation a echoue (voir les messages ci-dessus)"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# compilation (analysis & synthesis, fitter, assembler, timing analyzer)
# -----------------------------------------------------------------------------
compiler_projet() {
    trouver_quartus || return 1
    info "compilation du projet avec $QUARTUS_ROOTDIR (1 a 2 minutes)"
    local log="$PROJET/output_files/compilation.log"
    mkdir -p "$PROJET/output_files"
    (
        cd "$PROJET" &&
        "$QBIN/quartus_map" DecodeurIR &&
        "$QBIN/quartus_fit" DecodeurIR &&
        "$QBIN/quartus_asm" DecodeurIR &&
        "$QBIN/quartus_sta" DecodeurIR
    ) > "$log" 2>&1
    local rc=$?
    if [ $rc -ne 0 ]; then
        grep -E "^Error|^Critical" "$log" | head -n 20
        err "la compilation a echoue (journal complet : DecodeurIR/output_files/compilation.log)"
        return 1
    fi
    grep -E "^Info: Quartus Prime (Analysis & Synthesis|Fitter|Assembler|Timing Analyzer) was successful" "$log"
    ok "compilation reussie : DecodeurIR/$SOF"
}

# -----------------------------------------------------------------------------
# simulation modelsim / questa
# -----------------------------------------------------------------------------
VSIM=""
trouver_vsim() {
    if command -v vsim >/dev/null 2>&1; then
        VSIM="$(command -v vsim)"
        return 0
    fi
    local base c
    base="$(dirname "$QUARTUS_ROOTDIR")"
    for c in "$base/modelsim_ase/bin/vsim" "$base/modelsim_ae/bin/vsim" \
             "$base/questa_fse/bin/vsim" "$base/questa_fe/bin/vsim"; do
        if [ -x "$c" ]; then
            VSIM="$c"
            return 0
        fi
    done
    return 1
}

# met a jour la traduction vhdl du schema (si on a modifie DecodeurIR.bdf)
traduire_schema() {
    local dest="$PROJET/simulation/DecodeurIR_rtl.vhd"
    (cd "$PROJET" && "$QBIN/quartus_map" DecodeurIR --convert_bdf_to_vhdl=DecodeurIR.bdf) >/dev/null 2>&1 || return 0
    [ -f "$PROJET/DecodeurIR.vhd" ] || return 0
    {
        # en-tete explicatif du fichier actuel (jusqu'a la 2e ligne "-- ====")
        awk '{ print } /^-- =+$/ { if (++n == 2) exit }' "$dest"
        sed -e "s/^SIGNAL\tDFFE_inst4 :  STD_LOGIC;/SIGNAL\tDFFE_inst4 :  STD_LOGIC := '0';/" \
            -e "s/^SIGNAL\tSYNTHESIZED_WIRE_26 :  STD_LOGIC;/SIGNAL\tSYNTHESIZED_WIRE_26 :  STD_LOGIC := '0';/" \
            "$PROJET/DecodeurIR.vhd"
    } > "$dest.tmp" && mv "$dest.tmp" "$dest"
    rm -f "$PROJET/DecodeurIR.vhd"
}

# simulation de secours avec ghdl + gtkwave (si modelsim ne marche pas)
simuler_ghdl() {
    local nom="$1"
    local sim="$PROJET/simulation"
    local opts="--std=93c -fexplicit --ieee=synopsys -Wno-binding -Wno-hide"
    if ! command -v ghdl >/dev/null 2>&1 || ! command -v gtkwave >/dev/null 2>&1; then
        info "installation de ghdl et gtkwave (mot de passe administrateur demande)"
        sudo apt-get install -y ghdl gtkwave || {
            err "installe-les a la main : sudo apt install ghdl gtkwave"
            return 1
        }
    fi
    local comp="$PROJET/Comp_MaxValue.vhd" tb="tb_DecodeurIR"
    if [ "$nom" = "partie3" ]; then
        comp="$sim/partie3/Comp_MaxValue.vhd"
        tb="tb_partie3"
    fi
    mkdir -p "$sim/ghdl/work"
    (
        cd "$sim/ghdl/work" || exit 1
        # bibliotheque lpm : modeles de simulation fournis avec quartus
        if [ ! -f lpm-obj93.cf ]; then
            info "compilation de la bibliotheque lpm (une seule fois)"
            ghdl -a $opts --work=lpm "$QUARTUS_ROOTDIR/eda/sim_lib/220pack.vhd" \
                "$QUARTUS_ROOTDIR/eda/sim_lib/220model.vhd" || exit 1
        fi
        rm -f work-obj93.cf
        ghdl -a $opts "$PROJET/Counter_Nbits.vhd" "$comp" "$PROJET/ShiftReg24bits.vhd" \
            "$PROJET/CompLeadPulse.vhd" "$PROJET/CountMod48.vhd" "$PROJET/CompareTo47.vhd" \
            "$PROJET/Count2bits.vhd" "$PROJET/ShiftReg16bits.vhd" "$PROJET/FrameDecoder.vhd" \
            "$sim/DecodeurIR_rtl.vhd" "$sim/$tb.vhd" || exit 1
        ghdl -e $opts "$tb" || exit 1
        info "simulation ghdl en cours ($tb)$([ "$nom" = complet ] && echo ' : 2 a 3 minutes')"
        ghdl -r $opts "$tb" --wave="$nom.ghw" --read-wave-opt="../$nom.opt" --ieee-asserts=disable 2>&1 \
            | sed -n 's/.*(report note): /  /p; s/.*(assertion error): /  /p'
        [ -f "$nom.ghw" ] || exit 1
        gtkwave "$nom.ghw" "../$nom.gtkw" >/dev/null 2>&1 &
    )
}

simuler() {
    local nom="$1"
    trouver_quartus || return 1
    traduire_schema
    if [ "${2:-}" != "ghdl" ]; then
        if trouver_vsim; then
            info "lancement de $(basename "$VSIM") : sim_$nom.do"
            if (cd "$PROJET/simulation" && "$VSIM" -do "sim_$nom.do"); then
                return 0
            fi
            err "modelsim / questa n'a pas pu se lancer : simulation avec ghdl a la place"
        else
            info "modelsim / questa introuvable : simulation avec ghdl a la place"
        fi
    fi
    simuler_ghdl "$nom"
}

# -----------------------------------------------------------------------------
case "${1:-carte}" in
    carte|programmer)  programmer ;;
    compiler)          compiler_projet && programmer ;;
    ouvrir)            trouver_quartus && ("$QBIN/quartus" "$PROJET/DecodeurIR.qpf" >/dev/null 2>&1 &) ;;
    simulation)        simuler complet "${2:-}" ;;
    simulation3)       simuler partie3 "${2:-}" ;;
    usb)               config_usb ;;
    *)                 sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
