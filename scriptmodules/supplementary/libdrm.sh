#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="libdrm"
rp_module_desc="libdrm - userspace library for drm"
rp_module_licence="MIT https://www.mesa3d.org/license.html"
rp_module_repo="git https://github.com/freedesktop/mesa-drm libdrm-2.4.114"
rp_module_section="depends"
rp_module_flags="armbian"

function depends_libdrm() {
    local depends=(meson ninja-build libgbm-dev libdrm-dev libpciaccess-dev)

    getDepends "${depends[@]}"
}

function sources_libdrm() {
    gitPullOrClone
}

function build_libdrm() {
    local params=()
    
    params+=(-Dintel=disabled -Dradeon=disabled \
            -Damdgpu=disabled -Dexynos=disabled \
            -Dnouveau=disabled -Dvmwgfx=disabled \
            -Domap=disabled -Dfreedreno=disabled \
            -Dtegra=disabled -Detnaviv=disabled \
            -Dvc4=disabled)

    meson builddir --prefix=/usr/local "${params[@]}"
    ninja -C builddir

    md_ret_require="$md_build/builddir/tests/modetest/modetest"
}

function install_libdrm() {
    ninja -C builddir install
    ldconfig
}