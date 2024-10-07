#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="armbian-audiosettings"
rp_module_desc="Configure audio settings with dmix"
rp_module_section="config"
rp_module_flags="!all armbian"

function depends_audiosettings() {
    if [[ "$md_mode" == "install" ]]; then
        getDepends alsa-utils
    fi
}

function gui_armbian-audiosettings() {
    # Check if there are any ALSA sound cards detected
    if [[ `aplay -ql | wc -l` < 1 ]]; then
        printMsgs "dialog" "No sound cards detected or onboard audio disabled"
        return
    fi

    # Auto-configure dmixer
    _alsa_audiosettings $hw
}

function _autoconfigure_dmix_audiosettings() {
    local hw=$1  # Pass the sound card hardware number

    # Target config file (system-wide or user-specific)
    local config_file="/etc/asound.conf"
    [[ ! -w "$config_file" ]] && config_file="$home/.asoundrc"  # Use user config if system config is not writable

    # Create the ALSA configuration for dmix
    cat << EOF > "$config_file"
pcm.!default {
  type plug
  slave.pcm "dmixer"
}

pcm.dmixer  {
  type dmix
  ipc_key 1024
  slave {
    pcm "hw:$hw,0"
    channels 2          # Ensures stereo output
    period_time 0
    period_size 1024
    buffer_size 4096
    rate 48000
  }
  bindings {
    0 0
    1 1
  }
}

ctl.dmixer {
  type hw
  card $hw
}

ctl.!default {
    type hw
    card $hw
}
EOF

    # Apply the new ALSA configuration
    alsactl store
    printMsgs "dialog" "Audio output configured with dmix for sound card hw:$hw"
}

function _reset_alsa_audiosettings() {
    /etc/init.d/alsa-utils reset
    alsactl store
    rm -f "$home/.asoundrc" "/etc/alsa/conf.d/99-audiosettings.conf"
    printMsgs "dialog" "Audio settings reset to defaults"
}

function _alsa_audiosettings() {
    local cmd=(dialog --backtitle "$__backtitle" --menu "Set audio output (ALSA)" 22 86 16)
    local options=()
    local card_index
    local card_label

    # Get the list of sound cards from ALSA
    while read card_no card_label; do
        options+=("$card_no" "$card_label")
    done < <(aplay -ql | sed -En -e '/^card/ {s/^card ([0-9]+): ([^[]+).*/\1 \2/; s/hdmi[- ]?/HDMI /i; p}')
    
    options+=(
        M "Mixer - adjust output volume"
        R "Reset to default"
    )

    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [[ -n "$choice" ]]; then
        case "$choice" in
            [0-9])
                _autoconfigure_dmix_audiosettings $choice
                printMsgs "dialog" "Set audio output to ${options[$((choice*2+1))]}"
                ;;
            M)
                alsamixer >/dev/tty </dev/tty
                alsactl store
                ;;
            R)
                _reset_alsa_audiosettings
                ;;
        esac
    fi
}
