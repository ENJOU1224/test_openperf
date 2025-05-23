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
DOCKER_WORK_DIR = /home/openperf
RESULT_BASE_DIR   := result
DOCKER_RESULT_BASE_DIR   := $(DOCKER_WORK_DIR)/result

# --- gem5 相关配置 ---
DOCKER_GEM5_EXECUTABLE   := $(DOCKER_WORK_DIR)/GEM5/build/RISCV/gem5.opt
DOCKER_GEM5_CONFIG_SCRIPT:= $(DOCKER_WORK_DIR)/GEM5/configs/example/xiangshan.py

# 参数检查规则（私有目标，用下划线前缀表示内部使用）
_validate_para:
		@if ! echo "$(valid_paras)" | grep -qw "$(para)"; then \
        echo "error: invalid para='$(para)'. valid options: $(valid_paras)"; \
        exit 1; \
		fi

# 帮助信息
help:
		@echo "available parameters:"
		@for desc in $(param_descs); do \
        para=$${desc%%=*}; \
        description=$${desc#*=}; \
        printf "  %-10s - %s\n" "$$para" "$$description"; \
    done
		@echo ""
		@echo "usage: make gem5-* [para=value]"

nemu-%:
	docker compose exec openperf1 ./script/compilecommon.sh $*

gem5-tcc:_validate_para
	$(eval APP_NAME := $*)
	$(eval RUN_DIR := $(result_base_dir)/$(app_name)/$(app_name)-$(cpu_profile))
	$(eval DOCKER_RUN_DIR := $(DOCKER_RESULT_BASE_DIR)/$(app_name)/$(app_name)-$(cpu_profile))
	$(eval DOCKER_INPUT_BINARY_PATH := $(DOCKER_WORK_DIR)/nexus-am/apps/$(app_name)/build/riscv-tcc-riscv64-xs.bin)

	@mkdir -p $(run_dir)
	@find $(run_dir) -mindepth 1 -delete

	@mkdir -p $(run_dir)
	@find $(run_dir) -mindepth 1 -delete

	@docker compose exec \
		-w $(DOCKER_RUN_DIR) \
		openperf1 \
		$(DOCKER_GEM5_EXECUTABLE) $(DOCKER_GEM5_CONFIG_SCRIPT) \
		--ideal-kmhv3 \
		--cpu-profile=$(PARA) \
		--raw-cpt \
		--generic-rv-cpt=$(DOCKER_INPUT_BINARY_PATH) 

		@mv $(RUN_DIR)/m5out/* $(RUN_DIR)
	@echo "Completed: App='$(APP_NAME)', Profile='$(CPU_PROFILE)', Output: $(RUN_DIR)/m5out"

gem5-%:_validate_para
	$(eval APP_NAME := $*)
	$(eval RUN_DIR := $(RESULT_BASE_DIR)/$(APP_NAME)/$(APP_NAME)-$(CPU_PROFILE))
	$(eval DOCKER_RUN_DIR := $(DOCKER_RESULT_BASE_DIR)/$(APP_NAME)/$(APP_NAME)-$(CPU_PROFILE))
	$(eval DOCKER_INPUT_BINARY_PATH := $(DOCKER_WORK_DIR)/nexus-am/apps/$(APP_NAME)/build/$(APP_NAME)-riscv64-xs.bin)

	@mkdir -p $(RUN_DIR)
	@find $(RUN_DIR) -mindepth 1 -delete

	@docker compose exec \
		-w $(DOCKER_RUN_DIR) \
		openperf1 \
		$(DOCKER_GEM5_EXECUTABLE) $(DOCKER_GEM5_CONFIG_SCRIPT) \
		--ideal-kmhv3 \
		--cpu-profile=$(PARA) \
		--raw-cpt \
		--generic-rv-cpt=$(DOCKER_INPUT_BINARY_PATH) 

		@mv $(RUN_DIR)/m5out/* $(RUN_DIR)
	@echo "Completed: App='$(APP_NAME)', Profile='$(CPU_PROFILE)', Output: $(RUN_DIR)"

fix:
	docker compose exec openperf1 ./script/fix.sh
env:
		@mv $(RUN_DIR)/m5out/* $(RUN_DIR)
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
