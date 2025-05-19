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

# 遍历所有程序
for program in "${programs[@]}"; do
    # 遍历所有参数组合
    for param in "${params[@]}"; do
        cmd="make gem5-${program} PARA=${param}"
        log_file="${log_dir}/${program}_${param}.log"
        
        echo "Running: $cmd"
        $cmd > "$log_file" 2>&1
        
        # 检查执行结果
        if [ $? -eq 0 ]; then
            echo "✅ Success: $cmd"
        else
            echo "❌ Failed: $cmd (see $log_file)"
        fi
    done
    
    # 执行无参数版本
    cmd="make gem5-${program}"
    log_file="${log_dir}/${program}_none.log"
    
    echo "Running: $cmd"
    $cmd > "$log_file" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Success: $cmd"
    else
        echo "❌ Failed: $cmd (see $log_file)"
    fi
done

echo "All tests completed. Logs saved to: $log_dir"
