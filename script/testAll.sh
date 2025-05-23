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

# 创建日志目录
log_dir="test_logs"
mkdir -p "$log_dir"
echo "日志目录: $log_dir"

# --- 并行控制与执行 ---
max_jobs=3 # 设置最大并行任务数
declare -A pids_info # 关联数组存储 PID 和对应信息
declare -a pids_order # 数组按顺序存储 PID，用于后续按启动顺序检查

echo "开始执行任务，最大并行数: $max_jobs"

# 遍历所有程序和参数组合
for program in "${programs[@]}"; do
    # --- 带参数的任务 ---
    for param in "${params[@]}"; do
        # 检查当前运行的任务数，如果达到上限则等待一个任务结束
        # 'jobs -p' 列出当前 shell 启动的后台任务的 PID
        # 'wc -l' 计算行数，即任务数
        while [[ $(jobs -p | wc -l) -ge $max_jobs ]]; do
            # 'wait -n' 等待任意一个后台任务结束
            # 在等待前可以加个短暂休眠，避免过于频繁地检查 (可选)
            # sleep 0.1
            wait -n
        done

        # 构造命令和日志文件路径
        cmd="make gem5-${program} PARA=${param}"
        log_file="${log_dir}/${program}_${param}.log"

        echo "启动任务: $cmd (日志: $log_file)"
        # 在后台执行任务，并重定向输出
        # 使用 eval 可以更好地处理命令中可能存在的特殊字符（虽然此处可能非必需）
        ( eval "$cmd" > "$log_file" 2>&1 ) &
        pid=$! # 获取最后一个后台进程的 PID
        pids_info[$pid]="$cmd --- $log_file" # 存储 PID 和信息
        pids_order+=($pid) # 按顺序记录 PID
    done

    # --- 无参数版本的任务 ---
    # 同样检查并发限制
    while [[ $(jobs -p | wc -l) -ge $max_jobs ]]; do
        wait -n
    done

    cmd="make gem5-${program}"
    log_file="${log_dir}/${program}_none.log"

    echo "启动任务: $cmd (日志: $log_file)"
    ( eval "$cmd" > "$log_file" 2>&1 ) &
    pid=$!
    pids_info[$pid]="$cmd --- $log_file"
    pids_order+=($pid)
done

# --- 等待所有剩余任务完成 ---
echo "所有任务已启动，等待剩余的后台任务全部完成..."
wait # 等待当前 shell 的所有后台子进程结束

# --- 检查所有任务的最终状态 ---
echo "所有任务已完成，开始检查执行结果..."
all_success=true
failed_jobs=0
success_jobs=0

for pid in "${pids_order[@]}"; do
    info="${pids_info[$pid]}"
    cmd_str=$(echo "$info" | sed 's/ --- .*//')
    log_file_str=$(echo "$info" | sed 's/.* --- //')

    # 'wait $pid' 在这里会立即返回（因为上面已经 wait 过了）
    # 主要目的是获取特定 PID 的退出状态码 $?
    if wait $pid; then
        # 如果 wait $pid 成功（退出码为0），则任务成功
        echo "✅ 成功 (进程ID $pid): $cmd_str"
        ((success_jobs++))
    else
        # 如果 wait $pid 失败（退出码非0），则任务失败
        exit_status=$?
        echo "❌ 失败 (进程ID $pid, 退出码 $exit_status): $cmd_str (详见 $log_file_str)"
        all_success=false
        ((failed_jobs++))
    fi
done

echo "----------------------------------------"
echo "所有测试已完成。"
echo "总结: ${success_jobs} 个成功, ${failed_jobs} 个失败。"
echo "日志已保存到: $log_dir"

# 如果有任何任务失败，则以非零状态退出
if ! $all_success; then
    exit 1
fi

exit 0
