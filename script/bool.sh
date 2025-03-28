#!/bin/bash
# 要修复的文件路径
c_file="$OPENPERF_HOME/src/mcf/include/mcf.h"

# 检查文件是否存在
if [ ! -f "$c_file" ]; then
  echo "错误：文件不存在 $c_file" >&2
  exit 1
fi

# 检查文件中是否已经包含 #include <stdbool.h>
if ! grep -q '#include <stdbool.h>' "$c_file"; then
  # 在包含 "#include <test.h>" 的行后插入 "#include <stdbool.h>"
  sed -i '/#include <openlibm.h>/a#include <stdbool.h>' "$c_file"
  echo "已添加：$c_file 中的 #include <stdbool.h>"
else
  echo "$c_file 已经包含 #include <stdbool.h>"
fi

echo "修复完成：$c_file"
