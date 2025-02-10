#! /usr/bin/env bash

git clone git@github.com:OpenXiangShan/qemu.git -b checkpoint       
git clone https://github.com/OpenXiangShan/LibCheckpoint -b fix_bar      e_metal

git clone https://github.com/OpenXiangShan/nexus-am.git

export AM_HOME=~/nexus-am 
export QEMU_HOME=~/qemu 
export LIBCHECKPOINT_HOME=~/LibCheckpoint
export CROSS_COMPILE=riscv64-linux-gnu-

cd $QEMU_HOME || return
mkdir -p build
cd build || return
../configure --target-list=riscv64-softmmu --enable-debug --enable-zstd --enable-plugins
make clean
make -j "$(nproc)"

cd $LIBCHECKPOINT_HOME || return
git submodule update --init --recursive
make clean
make USING_BARE_METAL_WORKLOAD=1 GCPT_PAYLOAD_PATH=$AM_HOME/apps/linpack/build/linpack-riscv64-xs.bin GCPT_PAYLOAD_POSITION=0x80100000
