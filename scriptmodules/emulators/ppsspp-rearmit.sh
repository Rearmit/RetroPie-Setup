#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="ppsspp-rearmit"
rp_module_desc="PlayStation Portable emulator PPSSPP v1.14.4"
rp_module_help="ROM Extensions: .iso .pbp .cso\n\nCopy your PlayStation Portable roms to $romdir/psp"
rp_module_licence="GPL2 https://raw.githubusercontent.com/hrydgard/ppsspp/master/LICENSE.TXT"
rp_module_repo="git https://github.com/hrydgard/ppsspp.git v1.14.4"
rp_module_section="opt"
rp_module_flags="!all armbian"

function depends_ppsspp-rearmit() {
    depends_ppsspp
}

function sources_ppsspp-rearmit() {
    sources_ppsspp
}

function build_ppsspp-rearmit() {
    rpSwap on 1000

    local ppsspp_binary="PPSSPPSDL"
    local cmake="cmake"
    if hasPackage cmake 3.6 lt; then
        build_cmake_ppsspp
        cmake="$md_build/cmake/bin/cmake"
    fi

    # build ffmpeg
    build_ffmpeg_ppsspp "$md_build/ppsspp/ffmpeg"

    # build ppsspp
    cd "$md_build/ppsspp"
    rm -rf CMakeCache.txt CMakeFiles
    local params=()
    params+=(
        -DVULKAN=OFF \
        -DUSE_FFMPEG=ON \
        -DUSE_SYSTEM_FFMPEG=OFF \
        -DUSING_FBDEV=ON \
        -DUSE_WAYLAND_WSI=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DUSE_DISCORD=OFF \
        -DANDROID=OFF \
        -DWIN32=OFF \
        -DAPPLE=OFF \
        -DUNITTEST=OFF \
        -DSIMULATOR=OFF \
        -DUSING_QT_UI=OFF \
        -DHEADLESS=ON \
        -DMOBILE_DEVICE=OFF \
        -DUSING_X11_VULKAN=OFF \
        -DARM=ON \
        -DUSING_GLES2=ON \
        -DUSING_EGL=OFF
    )
    if isPlatform "aarch64" ; then
        params+=(-DARM64=ON)
    fi
    params+=(-DCMAKE_C_FLAGS="${CFLAGS/-DEGL_NO_X11=1/-DMESA_EGL_NO_X11_HEADERS=1/}")
    params+=(-DCMAKE_CXX_FLAGS="${CXXFLAGS}")
    "$cmake" "${params[@]}" .
    make clean
    make

    rpSwap off
    md_ret_require="$md_build/ppsspp/$ppsspp_binary"
}

function install_ppsspp-rearmit() {
    install_ppsspp
}

function configure_ppsspp-rearmit() {
    configure_ppsspp
}
