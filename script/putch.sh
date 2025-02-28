#!/bin/bash

# 使用 $T1_HOME 环境变量定位 openperf 目录
openperf_dir="$OPENPERF_HOME"

# 递归查找并替换所有 .c 和 .h 文件中的 putch( 为 _putchar(
find "$openperf_dir" -type f \( -name "*.c" -o -name "*.h" \) -exec grep -I -l "putch(" {} \; | while read -r file; do
    # 显示正在处理的文件
    echo "正在修改文件: $file"
    
    # 执行精确替换（原地修改）
     sed -i 's/\bputch(/_putc(/g' "$file"
    #sed -i '/\bputch(/d' "$file"
    
    # # 检查替换是否成功
    # if grep -q "_putchar(" "$file"; then
    #     echo "  ✓ 已替换：$file"
    # else
    #     echo "  ⚠️ 未找到需要替换的内容：$file"
    # fi
done

echo "操作完成！所有符合条件的 putch() 调用已替换为 _putchar()"
