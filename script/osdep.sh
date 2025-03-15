#!/bin/bash

target_file="$OPENPERF_HOME/src/x264/common/osdep.h"

sed -i -E '
# 第一部分：删除条件判断和宏定义
/#if[[:space:]]+defined\(__GNUC__\)[[:space:]]*&&[[:space:]]*\(__GNUC__[[:space:]]*> 3 \|\| __GNUC__[[:space:]]*== 3 && __GNUC_MINOR__[[:space:]]*> 3\)/,/#else/{
    d  # 删除从#if到#else的所有行（含边界）
}

# 第二部分：删除函数结尾的#endif
/return[[:space:]]+z[[:space:]]+\+[[:space:]]+lut\[x&0xf\];/{
    :loop
    N  # 读取下一行到模式空间
    /}[[:space:]]*\n[[:space:]]*#[[:space:]]*endif/{
        s/\n[[:space:]]*#[[:space:]]*endif//  # 替换换行和#endif为空
        b  # 跳出循环
    }
    b loop  # 继续循环直到匹配
}
' "$target_file"

echo "处理完成，已精确删除目标内容"
