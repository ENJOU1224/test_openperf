#! /usr/bin/env bash

docker compose exec openperf1 $SCRIPT_HOME/gem5_fix.sh # 为xiangshan连上RTC

cd $GEM5 || exit
bash ./init.sh
docker compose exec openperf1 scons build/RISCV/gem5.opt --gold-linker -j "$(nproc)"
