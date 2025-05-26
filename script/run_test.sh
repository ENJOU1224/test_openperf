#!/bin/bash

# 定义程序列表和参数列表
programs=(
    gemm
    linpack
    mcf
    stream
    tcc
    whetstone
    x264
)

params=(
    frontend_L0
    frontend_L1
    frontend_L2
    execution_L0
    execution_L1
    execution_L2
    memory_L0
    memory_L1
    memory_L2
    branch_L0
    branch_L1
    branch_L2
    branch_bandwidth_L0
    branch_bandwidth_L1
    branch_bandwidth_L2
    cache_L0
    cache_L1
    cache_L2
)

# 创建/使用固定的日志目录
log_dir="test_logs"
mkdir -p "$log_dir" # 确保日志目录存在，如果不存在则创建它

echo "日志将保存到: $log_dir (同名旧日志将被覆盖)"

# --- 并行控制与执行 ---
max_jobs=1 # 设置最大并行任务数，默认为1

echo "开始执行所有测试任务，最大并行数: $max_jobs"
echo "----------------------------------------"

# 遍历所有程序和参数组合
for program in "${programs[@]}"; do
    # --- 带参数的任务 ---
    for param in "${params[@]}"; do
        while [[ $(jobs -p | wc -l) -ge $max_jobs ]]; do
            wait -n
        done

        cmd="make gem5-${program} PARA=${param}"
        log_file="${log_dir}/${program}_${param}.log" # 日志文件会被覆盖

        echo "启动: $cmd -> ${log_file}"
        # 使用 > 会覆盖已存在的同名日志文件
        ( eval "$cmd" > "$log_file" 2>&1 ) &
    done

    # --- 无参数版本的任务 ---
    while [[ $(jobs -p | wc -l) -ge $max_jobs ]]; do
        wait -n
    done

    cmd_no_param="make gem5-${program}"
    log_file_no_param="${log_dir}/${program}_NO_PARAM.log" # 日志文件会被覆盖

    echo "启动: $cmd_no_param -> ${log_file_no_param}"
    # 使用 > 会覆盖已存在的同名日志文件
    ( eval "$cmd_no_param" > "$log_file_no_param" 2>&1 ) &
done

# --- 等待所有剩余任务完成 ---
echo "----------------------------------------"
echo "所有任务已启动，正在等待所有后台任务完成..."
wait

echo "========================================"
echo "所有测试任务已执行完毕。"
echo "请检查 '$log_dir' 目录下的日志文件以获取每个任务的详细输出和执行结果。"
echo "脚本执行完成。"
exit 0
