#!/bin/bash

# 设置目标目录
TARGET_DIR="$OPENPERF_HOME/src/common"

# 遍历目标目录下的所有子目录
for dir in "$TARGET_DIR"/*/; do
  # 检查是否是目录
  if [ -d "$dir"  ]; then
    # 检查是否存在 Makefile
    if [ -f "$dir/Makefile"  ]; then
      # 检查 Makefile 中是否包含 "LIBS += klib"
      if ! grep -q "LIBS += klib" "$dir/Makefile"; then
        # 如果不包含，则追加 "LIBS += klib" 到 Makefile
        echo "LIBS += klib" >> "$dir/Makefile" echo "已更新：$dir/Makefile"
      else echo "无需更新：$dir/Makefile" fi else echo "未找到 Makefile：$dir"
        fi fi done
