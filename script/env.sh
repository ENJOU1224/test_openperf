#! /usr/bin/env bash

git clone https://github.com/OpenXiangShan/nexus-am.git
git clone https://github.com/OpenXiangShan/NEMU.git
git clone -b origin/main https://github.com/OSCPU/openperf.git
git clone https://github.com/OpenXiangshan/GEM5.git 
wget  -nc https://github.com/OpenXiangShan/GEM5/releases/download/2024-10-16/riscv64-nemu-interpreter-c1469286ca32-so

export T1_HOME=$PWD
export AM_HOME=$PWD/nexus-am 
export GEM5=$PWD/GEM5
export OPENPERF_HOME=$PWD/openperf
export NEMU_HOME=$PWD/NEMU 
export SCRIPT_HOME=$PWD/script 
export LINUX_GNU_TOOLCHAIN=1
export GCBV_REF_SO=$T1_HOME/riscv64-nemu-interpreter-c1469286ca32-so
