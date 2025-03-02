#! /usr/bin/env bash

export GEM5_HOME=$T1_HOME/GEM5

$SCRIPT_HOME/gem5_fix.sh # 为xiangshan连上RTC

cd $GEM5_HOME || exit
bash ./init.sh
scons build/RISCV/gem5.opt --gold-linker -j "$(nproc)"
