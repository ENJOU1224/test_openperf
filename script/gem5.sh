#! /usr/bin/env bash

git clone https://github.com/OpenXiangshan/GEM5.git 

export GEM5_HOME=$T1_HOME/GEM5

cd $GEM5_HOME || exit
bash ./init.sh
scons build/RISCV/gem5.opt --gold-linker -j "$(nproc)"
