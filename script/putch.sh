#!/bin/bash

# 使用 $T1_HOME 环境变量定位 openperf 目录
openperf_dir="$OPENPERF_HOME"

# 递归查找并替换所有 .c 和 .h 文件中的 putch( 为 _putchar(,后者为香山am中puchar的函数名
find "$openperf_dir" -type f \( -name "*.c" -o -name "*.h" \) -exec grep -I -l "putch(" {} \; | while read -r file; do
    # 显示正在处理的文件
    echo "正在修改文件: $file"
    
    # 执行精确替换（原地修改）
     sed -i 's/\bputch(/_putc(/g' "$file"
    
done

echo "操作完成！所有符合条件的 putch() 调用已替换为 _putchar()"
