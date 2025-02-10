#!/bin/bash
# 脚本功能：
#   对 $OPENPERF_HOME/src/cpuemu/main.cc 与 $OPENPERF_HOME/src/linpack/linpack.c 中的 ioe_init 进行替换，
#   仅将没有下划线前缀的 ioe_init 替换为 _ioe_init，从而避免重复替换。

# 检查环境变量是否设置
if [ -z "$OPENPERF_HOME" ]; then
    echo "错误：OPENPERF_HOME 环境变量未设置！"
    exit 1
fi

# 定义需要处理的文件列表
files=(
    "$OPENPERF_HOME/src/cpuemu/main.cc"
    "$OPENPERF_HOME/src/linpack/linpack.c"
)

# 使用 sed 进行替换，注意：GNU sed 下使用 -i 直接原地修改
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        # 这里使用扩展正则表达式 (-E)，匹配 io_init 前如果不是下划线的情况
        sed -i -E 's/(^|[^_])ioe_init/\1_ioe_init/g' "$file"
        echo "已更新: $file"
    else
        echo "未找到文件: $file"
    fi
done

