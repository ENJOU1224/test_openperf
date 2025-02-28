#!/bin/bash

# 要修改的文件路径（请填写）
bitstream_file="$OPENPERF_HOME/src/x264/common/bitstream.h"

# 检查文件是否存在
if [ ! -f "$bitstream_file" ]; then
  echo "错误：文件不存在 $bitstream_file" >&2
  exit 1
fi

# 检查并替换 bs_realign 中的特定行
if grep -q "static inline void bs_realign( bs_t \*s )" "$bitstream_file"; then
  sed -i '/static inline void bs_realign( bs_t \*s )/,/^}/s/s->p       = (uint8_t\*)s->p - offset;/s->p = (uint8_t\*)((intptr_t)s->p >> 2 << 2);/' "$bitstream_file"
  echo "已修改：$bitstream_file 中的 bs_realign 函数"
else
  echo "错误：$bitstream_file 中未找到 bs_realign 函数" >&2
  exit 1
fi

echo "修改完成：$bitstream_file"
