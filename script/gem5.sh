#! /usr/bin/env bash

git clone https://github.com/OpenXiangshan/GEM5.git 

export GEM5_HOME=$T1_HOME/GEM5

# DRAMSim3
cd $GEM5_HOME/ext/dramsim3 || return
git clone git@github.com:umd-memsys/DRAMSim3.git DRAMSim3
cd DRAMSim3 || return
mkdir build 
cd build || return
cmake ..
make -j "$(nproc)" 

# GEM5
cd $GEM5_HOME || return
scons build/RISCV/gem5.opt --gold-linker -j "$(nproc)"
