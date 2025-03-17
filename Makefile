coremark:

nemu-%:
	./script/CompileCommon.sh $*

gem5-tcc:
	$(GEM5_HOME)/build/RISCV/gem5.opt $(GEM5_HOME)/configs/example/xiangshan.py --raw-cpt --generic-rv-cpt=$(AM_HOME)/apps/tcc/build/riscv-tcc-riscv64-xs.bin

gem5-%:
	$(GEM5_HOME)/build/RISCV/gem5.opt $(GEM5_HOME)/configs/example/xiangshan.py --raw-cpt --generic-rv-cpt=$(AM_HOME)/apps/$*/build/$*-riscv64-xs.bin
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
