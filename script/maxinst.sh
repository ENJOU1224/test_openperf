#!/bin/bash

# 调整GEM5最大指令数量以适配大规模的测试
file="$GEM5/configs/common/Options.py"

    # 显示正在处理的文件
    echo "正在修改文件: $file"
    
    # 执行精确替换（原地修改）
    sed -i 's/40\*10\*\*6/None/g' "$file"
