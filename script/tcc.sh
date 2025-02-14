#!/bin/bash
# 目标文件
TCC_H_FILE="$OPENPERF_HOME/src/tcc/tcc.h"

# 检查文件是否存在
if [ ! -f "$TCC_H_FILE" ]; then
    echo "错误: 文件 $TCC_H_FILE 不存在！"
    exit 1
fi

# 使用 sed 删除包含 PRINTF_LIKE(1,2) 或 PRINTF_LIKE(2,3) 的整行
sed -i -E 's/\s*PRINTF_LIKE\(1,2\)//g; s/\s*PRINTF_LIKE\(2,3\)//g' "$TCC_H_FILE"

echo "已删除包含 PRINTF_LIKE(1,2) 或 PRINTF_LIKE(2,3) 的行：$TCC_H_FILE"
