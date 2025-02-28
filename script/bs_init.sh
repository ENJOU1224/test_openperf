#!/bin/bash

# 要修改的文件路径（请填写）
bitstream_file="$OPENPERF_HOME/src/x264/common/bitstream.h"

# 检查文件是否存在
if [ ! -f "$bitstream_file" ]; then
  echo "错误：文件不存在 $bitstream_file" >&2
  exit 1
fi

# 修改 bs_init
if grep -q "static inline void bs_init" "$bitstream_file"; then
  sed -i '/static inline void bs_init( bs_t \*s, void \*p_data, int i_data )/,/^}/c\
static inline void bs_init(bs_t *s, void *p_data, int i_data)\
{\
    int offset = ((intptr_t)p_data & 3);\
    uint8_t *new_p = (uint8_t*)p_data - offset;\
    if (offset && new_p >= (uint8_t*)p_data)\
    {\
        s->p = s->p_start = new_p;\
        s->i_left = (WORD_SIZE - offset)*8;\
        s->cur_bits = endian_fix32(M32(s->p));\
        s->cur_bits >>= (4-offset)*8;\
    }\
    else\
    {\
        s->p = s->p_start = (uint8_t*)p_data;\
        s->i_left = WORD_SIZE * 8;\
        s->cur_bits = 0;\
    }\
    s->p_end = (uint8_t*)p_data + i_data;\
}' "$bitstream_file"
  echo "已修改：$bitstream_file 中的 bs_init 函数"
else
  echo "错误：$bitstream_file 中未找到 bs_init 函数" >&2
  exit 1
fi

echo "修改完成：$bitstream_file"
