
common:
	./script/CompileCommon.sh

fix:
	./script/fix.sh
env:
	source ./script/env.sh

init:
	cd openperf && git checkout -- . && cd ..
	cd NEMU && git checkout -- . && cd ..
	cd nexus-am && git checkout -- . && cd ..

x264:
	cd openperf/src/x264 && make ARCH=riscv64-xs

nemu:
	cd NEMU && make clean && make riscv64-xs_defconfig && make -j
.PHONY: common init env nemu fix
