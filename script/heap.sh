#!/bin/bash

# 使用 $T1_HOME 描述路径
bench_malloc_file="$OPENPERF_HOME/src/common/bench/bench_malloc.c"

# 检查文件是否存在
if [ ! -f "$bench_malloc_file" ]; then
  echo "错误：文件不存在 $bench_malloc_file" >&2
  exit 1
fi

# 精确替换 heap 为 _heap（仅针对变量引用）
sed -i -E \
  -e 's/(bench_malloc_init\(\) \{ program_break = \(intptr_t\))heap\.start/\1_heap.start/' \
  -e 's/(bench_all_free\(\) \{ program_break = \(intptr_t\))heap\.start/\1_heap.start/' \
  "$bench_malloc_file"

echo "修复完成：$bench_malloc_file 中的 heap 已替换为 _heap"
