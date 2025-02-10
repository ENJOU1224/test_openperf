#!/bin/bash

# 使用 $T1_HOME 环境变量定位 openperf 目录
openperf_dir="$OPENPERF_HOME"

# 递归查找并替换所有 Makefile 文件中的 INC_PATH
find "$openperf_dir" -type f -name "Makefile" -exec grep -I -lw "INC_PATH" {} \; | while read -r file; do
    # 显示正在处理的文件
    echo "正在修改文件: $file"
    
    # 执行精确替换（原地修改）
    sed -i 's/\bINC_PATH\b/INC_DIR/g' "$file"
    
    # 检查替换是否成功
    if grep -q "INC_DIR" "$file"; then
        echo "  ✓ 已替换：$file"
    else
        echo "  ⚠️ 未找到需要替换的内容：$file"
    fi
done

echo "操作完成！所有符合条件的 INC_PATH 已替换为 INC_DIR"
