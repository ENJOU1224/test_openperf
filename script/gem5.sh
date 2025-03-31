#! /usr/bin/env bash

docker compose exec openperf1 script/gem5_fix.sh # 为xiangshan连上RTC

docker compose exec openperf1 bash -c "cd GEM5 && bash ./init.sh"
docker compose exec openperf1 bash -c "cd GEM5 && scons build/RISCV/gem5.opt --gold-linker -j "$(nproc)""
