#!/bin/bash

# 使用 $T1_HOME 描述路径
bench_c_file="$OPENPERF_HOME/src/common/bench/bench.c"

# 检查文件是否存在
if [ ! -f "$bench_c_file" ]; then
  echo "错误：文件不存在 $bench_c_file" >&2
  exit 1
fi

# 检查是否包含 amdev.h，如果没有则添加
if ! grep -q '#include "amdev.h"' "$bench_c_file"; then
  sed -i '1i#include "amdev.h"' "$bench_c_file"
  echo "已添加：$bench_c_file 中的 #include \"amdev.h\""
fi

# 替换 uptime 函数
sed -i '/^uint64_t uptime() {/,/^}/ {
  /^uint64_t uptime() {/ {
    r /dev/stdin
    d
  }
}' "$bench_c_file" <<EOF
uint64_t uptimes() {
    _DEV_TIMER_UPTIME_t uptime;
    _io_read(_DEV_TIMER, _DEVREG_TIMER_UPTIME, &uptime, sizeof(uptime));
    return (uint64_t)uptime.hi << 32 | (uint64_t)uptime.lo;
}
EOF

echo "修复完成：$bench_c_file"
