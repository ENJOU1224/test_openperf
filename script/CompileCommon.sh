#! /usr/bin/env bash

p1=${1:-linpack}

cp "$OPENPERF_HOME"/src/* "$AM_HOME/apps" -r
cd "$AM_HOME/apps/common/bench" && make ARCH=riscv64-xs || exit
cd "$AM_HOME/apps/common/soft-fp" && make ARCH=riscv64-xs || exit
cd "$AM_HOME/apps/common/openlibm" && make ARCH=riscv64-xs || exit
cd "$AM_HOME/apps/$p1" && make ARCH=riscv64-xs || exit
if [ "$p1" == "tcc" ]; then
    "$NEMU_HOME/build/riscv64-nemu-interpreter" -b "$AM_HOME/apps/$p1/build/riscv-$p1-riscv64-xs.bin"
else
    "$NEMU_HOME/build/riscv64-nemu-interpreter" -b "$AM_HOME/apps/$p1/build/$p1-riscv64-xs.bin"
fi
