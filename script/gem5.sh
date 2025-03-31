#! /usr/bin/env bash

$SCRIPT_HOME/gem5_fix.sh # 为xiangshan连上RTC

cd $GEM5 || exit
bash ./init.sh
scons build/RISCV/gem5.opt --gold-linker -j "$(nproc)"
