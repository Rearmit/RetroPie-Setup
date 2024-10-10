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
rp_module_desc="Configure audio settings for Armbian"
rp_module_section="config"
rp_module_flags="!all armbian"

function depends_armbian-audiosettings() {
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

    _armbian_alsa_internal_audiosettings
}

function _reset_alsa_armbian-audiosettings() {
    /etc/init.d/alsa-utils reset
    alsactl store
    rm -f "$home/.asoundrc" "/etc/alsa/conf.d/99-retropie.conf"
    printMsgs "dialog" "Audio settings reset to defaults"
}

function _armbian_alsa_internal_audiosettings() {
    local cmd=(dialog --backtitle "$__backtitle" --menu "Set audio output (ALSA)" 22 86 16)
    local options=()
    local card_index
    local card_label

    # Get the list of Pi internal cards
    while read card_no card_label; do
        options+=("$card_no" "$card_label")
    done < <(aplay -ql | sed -En -e '/^card/ {s/^card ([0-9]+): [^[]* \[([^]]*)\].*/\1 \2/; p}')
    options+=(
        M "Mixer - adjust output volume"
        R "Reset to default"
    )

    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [[ -n "$choice" ]]; then
        case "$choice" in
            [0-9])
                _asoundrc_save_armbian-audiosettings $choice ${options[$((choice*2+1))]}
                printMsgs "dialog" "Set audio output to ${options[$((choice*2+1))]}"
                ;;
            M)
                alsamixer >/dev/tty </dev/tty
                alsactl store
                ;;
            R)
                _reset_alsa_armbian-audiosettings
                ;;
        esac
    fi
}

# configure the default ALSA soundcard based on chosen card index and type
function _asoundrc_save_armbian-audiosettings() {
    [[ -z "$1" ]] && return

    local card_index=$1
    local card_type=$2
    local tmpfile="$(mktemp)"

    if isPlatform "kms" && ! isPlatform "dispmanx" && [[ $card_type == "HDMI"* ]] || [[ $card_type == "hdmi"* ]]; then
        # when the 'vc4hdmi' driver is used instead of 'bcm2835_audio' for HDMI,
        # the 'hdmi:vchdmi[-idx]' PCM should be used for converting to the native IEC958 codec
        # adds a volume control since the default configured mixer doesn't work
        # (default configuration is at /usr/share/alsa/cards/vc4-hdmi.conf)
        local card_name="$(cat /proc/asound/card${card_index}/id)"
        cat << EOF > "$tmpfile"
pcm.hdmi${card_index} {
  type asym
  playback.pcm {
    type plug
    slave.pcm "hw:$card_index,0"
  }
}
ctl.!default {
  type hw
  card $card_index
}
pcm.softvolume {
    type           softvol
    slave.pcm      "hdmi${card_index}"
    control.name  "HDMI Playback Volume"
    control.card  ${card_index}
}

pcm.softmute {
    type softvol
    slave.pcm "softvolume"
    control.name "HDMI Playback Switch"
    control.card ${card_index}
    resolution 2
}

pcm.!default {
    type plug
    slave.pcm "softmute"
}
EOF
    else
    cat << EOF > "$tmpfile"
pcm.!default {
  type asym
  playback.pcm {
    type plug
    slave.pcm "output"
  }
}
pcm.output {
  type hw
  card $card_index
}
ctl.!default {
  type hw
  card $card_index
}
EOF
    fi
    local dest="$home/.asoundrc"
    mv "$tmpfile" "$dest"
    chmod 644 "$dest"
    chown $user:$user "$dest"
}
