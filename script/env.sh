#! /usr/bin/env bash

git clone https://github.com/OpenXiangShan/nexus-am.git
git clone https://github.com/OpenXiangShan/NEMU.git
git clone -b origin/main https://github.com/OSCPU/openperf.git

export T1_HOME=$PWD
export AM_HOME=$PWD/nexus-am 
export OPENPERF_HOME=$PWD/openperf
export NEMU_HOME=$PWD/NEMU 
export SCRIPT_HOME=$PWD/script 
export LINUX_GNU_TOOLCHAIN=1
