# Makefile

# --- ANSI Color Codes (直接给 echo 使用) ---
# make 会将这些变量的值直接传递给 shell 的 echo 命令
# 如果 shell 默认解释 ANSI codes (很多现代 shell 会) 或者 make 以某种方式促成，就能工作
COLOR_BOLD_GREEN   := \033[1;32m
COLOR_GREEN        := \033[0;32m
COLOR_CYAN         := \033[0;36m # 使用青色替代蓝色
COLOR_BOLD_CYAN    := \033[1;36m
COLOR_YELLOW       := \033[0;33m
COLOR_BOLD_YELLOW  := \033[1;33m
COLOR_RED          := \033[0;31m
COLOR_BOLD_RED     := \033[1;31m
COLOR_RESET        := \033[0m

# --- 常量和配置 ---
VALID_PARAS := frontend_L0 frontend_L1 frontend_L2 \
               execution_L0 execution_L1 execution_L2 \
               memory_L0 memory_L1 memory_L2 \
               branch_L0 branch_L1 branch_L2 \
               branch_bandwidth_L0 branch_bandwidth_L1 branch_bandwidth_L2 \
               cache_L0 cache_L1 cache_L2 \
               ''

DEFAULT_PARA := ''
PARA ?= $(DEFAULT_PARA)

DOCKER_WORK_DIR        := /home/openperf
RESULT_BASE_DIR      := result
DOCKER_RESULT_BASE_DIR := $(DOCKER_WORK_DIR)/$(RESULT_BASE_DIR)

DOCKER_GEM5_EXECUTABLE   := $(DOCKER_WORK_DIR)/GEM5/build/RISCV/gem5.opt
DOCKER_GEM5_CONFIG_SCRIPT:= $(DOCKER_WORK_DIR)/GEM5/configs/example/xiangshan.py

# --- 私有目标 ---
.PHONY: _validate_para
_validate_para:
	@if ! echo "$(VALID_PARAS)" | grep -qw "$(PARA)"; then \
		echo "$(COLOR_BOLD_RED)ERROR:$(COLOR_RESET) Invalid PARA='$(COLOR_YELLOW)$(PARA)$(COLOR_RESET)'."; \
		$(MAKE) help_paras; \
		exit 1; \
	fi

# --- 公共目标 ---
.PHONY: help help_paras test analyze nemu nemu-% fix init clean_results
.DEFAULT_GOAL := help

help:
	@echo "$(COLOR_BOLD_GREEN)Usage:$(COLOR_RESET) make $(COLOR_GREEN)<target>$(COLOR_RESET) [PARA=$(COLOR_CYAN)<parameter_value>$(COLOR_RESET)]"
	@echo ""
	@echo "$(COLOR_BOLD_CYAN)Available targets:$(COLOR_RESET)"
	@echo "  $(COLOR_GREEN)gem5-<app>$(COLOR_RESET)         Run gem5 simulation for $(COLOR_CYAN)<app>$(COLOR_RESET) (e.g., tcc, linpack, gemm)."
	@echo "  $(COLOR_GREEN)nemu-<app>$(COLOR_RESET)         Compile $(COLOR_CYAN)<app>$(COLOR_RESET) for NEMU."
	@echo "  $(COLOR_GREEN)nemu$(COLOR_RESET)               Compile NEMU itself."
	@echo "  $(COLOR_GREEN)fix$(COLOR_RESET)                Run fix script."
	@echo "  $(COLOR_GREEN)init$(COLOR_RESET)               Checkout submodules."
	@echo "  $(COLOR_GREEN)test$(COLOR_RESET)               Run testAll.sh script."
	@echo "  $(COLOR_GREEN)analyze$(COLOR_RESET)            Run analyze_result.py script."
	@echo "  $(COLOR_GREEN)clean_results$(COLOR_RESET)      Remove the '$(COLOR_YELLOW)$(RESULT_BASE_DIR)$(COLOR_RESET)' directory."
	@echo "  $(COLOR_GREEN)help_paras$(COLOR_RESET)         Show available PARA values for gem5-* targets."
	@echo "  $(COLOR_GREEN)help$(COLOR_RESET)               Show this help message."
	@echo ""
	@echo "Example: make $(COLOR_GREEN)gem5-linpack$(COLOR_RESET) PARA=$(COLOR_CYAN)frontend_L1$(COLOR_RESET)"

help_paras:
	@echo "$(COLOR_BOLD_CYAN)Available PARA values for gem5-* targets (leave empty or use '' for default):$(COLOR_RESET)"
	@for p in $(VALID_PARAS); do \
		if [ -z "$$p" ]; then \
			echo "  $(COLOR_GREEN)''$(COLOR_RESET) (empty string) - Default (no specific bottleneck parameter)"; \
		else \
			echo "  $(COLOR_GREEN)$$p$(COLOR_RESET)"; \
		fi; \
	done

nemu-%:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Compiling NEMU app '$(COLOR_CYAN)$*$(COLOR_RESET)'..."
	@docker compose exec openperf1 ./script/CompileCommon.sh $*

nemu:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Compiling NEMU..."
	@docker compose exec openperf1 bash -c "cd NEMU && make clean && make riscv64-xs_defconfig && make -j"

gem5-%: _validate_para
	$(eval APP_NAME := $*)
	$(eval RUN_DIR_SUFFIX := $(if $(PARA),$(PARA),default))
	$(eval RUN_DIR := $(RESULT_BASE_DIR)/$(APP_NAME)/$(APP_NAME)-$(RUN_DIR_SUFFIX))
	$(eval DOCKER_RUN_DIR := $(DOCKER_RESULT_BASE_DIR)/$(APP_NAME)/$(APP_NAME)-$(RUN_DIR_SUFFIX))

	$(eval _APP_BINARY_SUFFIX := -riscv64-xs.bin)
	$(if $(filter tcc,$(APP_NAME)), \
		$(eval DOCKER_INPUT_BINARY_PATH := $(DOCKER_WORK_DIR)/nexus-am/apps/$(APP_NAME)/build/riscv-$(APP_NAME)$(_APP_BINARY_SUFFIX)), \
		$(eval DOCKER_INPUT_BINARY_PATH := $(DOCKER_WORK_DIR)/nexus-am/apps/$(APP_NAME)/build/$(APP_NAME)$(_APP_BINARY_SUFFIX)) \
	)

	@echo "$(COLOR_BOLD_GREEN)Running gem5:$(COLOR_RESET) App='$(COLOR_CYAN)$(APP_NAME)$(COLOR_RESET)', Profile='$(COLOR_CYAN)$(RUN_DIR_SUFFIX)$(COLOR_RESET)', Output to: $(COLOR_CYAN)$(RUN_DIR)$(COLOR_RESET)"
	@mkdir -p $(RUN_DIR)
	@rm -rf $(RUN_DIR)/* 2>/dev/null || true
	@mkdir -p $(RUN_DIR) # Ensure directory exists after rm

	@docker compose exec \
		-w $(DOCKER_RUN_DIR) \
		openperf1 \
		$(DOCKER_GEM5_EXECUTABLE) $(DOCKER_GEM5_CONFIG_SCRIPT) \
		--ideal-kmhv3 \
		--cpu-profile=$(PARA) \
		--raw-cpt \
		--generic-rv-cpt=$(DOCKER_INPUT_BINARY_PATH)

	@if [ -d "$(RUN_DIR)/m5out" ]; then \
		mv $(RUN_DIR)/m5out/* $(RUN_DIR)/ 2>/dev/null || true; \
		rm -rf $(RUN_DIR)/m5out; \
	fi
	@echo "$(COLOR_BOLD_GREEN)Completed:$(COLOR_RESET) App='$(COLOR_CYAN)$(APP_NAME)$(COLOR_RESET)', Profile='$(COLOR_CYAN)$(RUN_DIR_SUFFIX)$(COLOR_RESET)', Output in: $(COLOR_CYAN)$(RUN_DIR)$(COLOR_RESET)"

fix:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Running fix script..."
	@docker compose exec openperf1 ./script/fix.sh

init:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Resetting submodules..."
	@cd openperf && git checkout -- . && echo "  $(COLOR_GREEN)openperf reset.$(COLOR_RESET)" && cd ..
	@cd NEMU && git checkout -- . && echo "  $(COLOR_GREEN)NEMU reset.$(COLOR_RESET)" && cd ..
	@cd nexus-am && git checkout -- . && echo "  $(COLOR_GREEN)nexus-am reset.$(COLOR_RESET)" && cd ..
	@echo "$(COLOR_GREEN)Submodules reset complete.$(COLOR_RESET)"

test:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Running testAll.sh script..."
	@./script/run_test.sh

analyze:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Running analyze_result.py script..."
	@python script/analyze_result.py

clean_results:
	@echo "$(COLOR_BOLD_YELLOW)INFO:$(COLOR_RESET) Removing result directory: $(COLOR_CYAN)$(RESULT_BASE_DIR)$(COLOR_RESET)..."
	@rm -rf $(RESULT_BASE_DIR)
	@echo "$(COLOR_GREEN)Result directory $(COLOR_CYAN)$(RESULT_BASE_DIR)$(COLOR_RESET) removed.$(COLOR_RESET)"
