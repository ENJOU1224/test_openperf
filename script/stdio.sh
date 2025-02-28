#!/bin/bash

# 要修复的文件路径
c_file="$OPENPERF_HOME/src/mcf/mcf.c"

# 检查文件是否存在
if [ ! -f "$c_file" ]; then
  echo "错误：文件不存在 $c_file" >&2
  exit 1
fi

# 检查文件中是否包含 #include <stdio.h>
if grep -q '#include <stdio.h>' "$c_file"; then
  # 删除包含 "#include <stdio.h>" 的行
  sed -i '/#include <stdio.h>/d' "$c_file"
  echo "已删除：$c_file 中的 #include <stdio.h>"
else
  echo "$c_file 中没有 #include <stdio.h>"
fi

echo "修复完成：$c_file"
