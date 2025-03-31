# 定义允许的参数列表和描述
VALID_PARAS := frontend execution memory branch cache ''
PARAM_DESCS := \
    frontend="Frontend bottleneck parameters" \
    execution="Execution contention parameters" \
    memory="Memory subsystem parameters" \
    branch="Branch prediction parameters" \
    cache="Cache hierarchy parameters" 

# 默认参数
DEFAULT_PARA := ''
PARA ?= $(DEFAULT_PARA)

# 参数检查规则（私有目标，用下划线前缀表示内部使用）
_validate_para:
		@if ! echo "$(VALID_PARAS)" | grep -qw "$(PARA)"; then \
        echo "Error: Invalid PARA='$(PARA)'. Valid options: $(VALID_PARAS)"; \
        exit 1; \
		fi

# 帮助信息
help:
		@echo "Available parameters:"
		@for desc in $(PARAM_DESCS); do \
        para=$${desc%%=*}; \
        description=$${desc#*=}; \
        printf "  %-10s - %s\n" "$$param" "$$description"; \
    done
		@echo ""
		@echo "Usage: make GEM5-* [PARA=value]"

nemu-%:
	docker compose exec openperf1 ./script/CompileCommon.sh $*

gem5-tcc:_validate_para
	docker compose exec openperf1 GEM5/build/RISCV/gem5.opt GEM5/configs/example/xiangshan.py --ideal-kmhv3 --cpu-profile=$(PARA) --raw-cpt --generic-rv-cpt=nexus-am/apps/tcc/build/riscv-tcc-riscv64-xs.bin
	mkdir -p result/tcc
	rm result/tcc/tcc-$(PARA) -rf
	mv m5out result/tcc/tcc-$(PARA)

gem5-%:_validate_para
	docker compose exec openperf1 GEM5/build/RISCV/gem5.opt GEM5/configs/example/xiangshan.py  --ideal-kmhv3 --cpu-profile=$(PARA) --raw-cpt --generic-rv-cpt=nexus-am/apps/$*/build/$*-riscv64-xs.bin
	mkdir -p result/$*
	rm result/$*/$*-$(PARA) -rf
	mv m5out result/$*/$*-$(PARA) 

fix:
	docker compose exec openperf1 ./script/fix.sh
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
.PHONY: common init env nemu fix _validate_para help
