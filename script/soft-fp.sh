#!/bin/bash

# 使用 $T1_HOME 描述路径
file_path="$OPENPERF_HOME/src/common/soft-fp/soft-fp.h"

# 检查文件是否存在
if [ ! -f "$file_path" ]; then
  echo "错误：文件不存在 $file_path" >&2
  exit 1
fi

# 删除指定行
sed -i '/#define FP_HANDLE_EXCEPTIONS do {} while (0)*/d' "$file_path"

echo "删除完成：$file_path 中的指定行已删除"
