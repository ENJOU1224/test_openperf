#!/bin/bash

# 定义要删除的文件夹路径
target_dir="$T1_HOME/openperf/src/common/ldecod_src"

# 检查文件夹是否存在
if [ -d "$target_dir" ]; then
  echo "正在删除文件夹: $target_dir"
  rm -rf "$target_dir"
  echo "文件夹已删除。"
else
  echo "文件夹不存在: $target_dir"
fi
