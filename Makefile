# 定义允许的参数列表和描述
VALID_PARAS := frontend_L0 frontend_L1 frontend_L2 execution_L0 execution_L1 execution_L2 memory_L0 memory_L1 memory_L2 branch_L0 branch_L1 branch_L2 branch_bandwidth_L0 branch_bandwidth_L1 branch_bandwidth_L2 cache_L0 cache_L1 cache_L2 ''
PARAM_DESCS := \
    frontend="Frontend bottleneck parameters" \
    execution="Execution contention parameters" \
    memory="Memory subsystem parameters" \
    branch="Branch prediction parameters" \
    cache="Cache hierarchy parameters" 

# 默认参数
DEFAULT_PARA := ''
PARA ?= $(DEFAULT_PARA)
RESULT_BASE_DIR   := $(T1_HOME)/result

# --- GEM5 相关配置 ---
GEM5_EXECUTABLE   := $(GEM5)/build/RISCV/gem5.opt
GEM5_CONFIG_SCRIPT:= $(GEM5)/configs/example/xiangshan.py

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
        printf "  %-10s - %s\n" "$$para" "$$description"; \
    done
		@echo ""
		@echo "Usage: make GEM5-* [PARA=value]"

nemu-%:
	docker compose exec openperf1 ./script/CompileCommon.sh $*

gem5-tcc:_validate_para
	$(eval APP_NAME := $*)
	$(eval CPU_PROFILE := $(PARA))
	$(eval RUN_DIR := $(RESULT_BASE_DIR)/$(APP_NAME)/$(APP_NAME)-$(CPU_PROFILE))
	$(eval INPUT_BINARY := $(AM_HOME)/apps/$(APP_NAME)/build/riscv-tcc-riscv64-xs.bin)

	@mkdir -p $(RUN_DIR)
	@find $(RUN_DIR) -mindepth 1 -delete

	@mkdir -p $(RUN_DIR)
	@find $(RUN_DIR) -mindepth 1 -delete

	@( \
		set -e; \
		cd $(RUN_DIR); \
		docker compose exec openperf1 $(GEM5_EXECUTABLE) $(GEM5_CONFIG_SCRIPT) \
			--ideal-kmhv3 \
			--cpu-profile=$(CPU_PROFILE) \
			--raw-cpt \
			--gen-eric-rv-cpt=$(INPUT_BINARY) \
	)

	@echo "Completed: App='$(APP_NAME)', Profile='$(CPU_PROFILE)', Output: $(RUN_DIR)/m5out"

gem5-%:_validate_para
	$(eval APP_NAME := $*)
	$(eval CPU_PROFILE := $(PARA))
	$(eval RUN_DIR := $(RESULT_BASE_DIR)/$(APP_NAME)/$(APP_NAME)-$(CPU_PROFILE))
	$(eval INPUT_BINARY := $(AM_HOME)/apps/$(APP_NAME)/build/$(APP_NAME)-riscv64-xs.bin)

	@mkdir -p $(RUN_DIR)
	@find $(RUN_DIR) -mindepth 1 -delete

	@( \
		set -e; \
		cd $(RUN_DIR); \
		docker compose exec openperf1 $(GEM5_EXECUTABLE) $(GEM5_CONFIG_SCRIPT) \
			--ideal-kmhv3 \
			--cpu-profile=$(CPU_PROFILE) \
			--raw-cpt \
			--gen-eric-rv-cpt=$(INPUT_BINARY) \
	)
	@echo "Completed: App='$(APP_NAME)', Profile='$(CPU_PROFILE)', Output: $(RUN_DIR)/m5out"

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
	docker compose exec openperf1 bash -c "cd NEMU && make clean && make riscv64-xs_defconfig && make -j"

test:
	./script/run_test.sh

analyze:
	python script/analyze_result.py
.PHONY: common init env nemu fix _validate_para help test analyze
