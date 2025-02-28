#!/bin/bash

# 使用 $T1_HOME 描述路径
printf_file="$OPENPERF_HOME/src/x264/common/osdep.h"

# 检查文件是否存在
if [ ! -f "$printf_file" ]; then
  echo "错误：文件不存在 $printf_file" >&2
  exit 1
fi

# 精确替换 heap 为 _heap（仅针对变量引用）
sed -i '/^#define sprintf my_sprintf/d' "$printf_file"

echo "修复完成：$printf_file 中的 sprint 宏定义已删除"
