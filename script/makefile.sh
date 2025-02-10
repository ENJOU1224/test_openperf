#! /usr/bin/env bash

# 定义 src 目录路径
src_dir="$OPENPERF_HOME/src"

# 遍历 src 目录下的所有 Makefile（排除 common 文件夹）
find "$src_dir" -path "$src_dir/common" -prune -o -name "Makefile" -print | while read -r makefile; do
  echo "正在处理: $makefile"

  # 添加 WORK_DIR = $(shell pwd)
  if ! grep -q "WORK_DIR = \$(shell pwd)" "$makefile"; then
    sed -i '1iWORK_DIR = $(shell pwd)' "$makefile"
  fi

  # 替换 include $(AM_HOME)/Makefile 为 include $(AM_HOME)/Makefile.app
  sed -i 's|include $(AM_HOME)/Makefile$|include $(AM_HOME)/Makefile.app|g' "$makefile"

  # 在 $(addsuffix /build/, $(addprefix $(AM_HOME)/, $(LIBS))) 中加上 /libs/
  sed -i 's|$(addsuffix /build/, $(addprefix $(AM_HOME)/, $(LIBS)))|$(addsuffix /build/, $(addprefix $(AM_HOME)/libs/, $(LIBS)))|g' "$makefile"

  sed -i '/^LINK_FILES/{
    N
    /\n[[:space:]]*\$[(]AM_HOME[)]/! {
        s/\(.*\\\)\n\([[:space:]]*\)/\1\n\2$(AM_HOME)\/am\/build\/am-$(ARCH).a \\\n\2/
          
  }
}' "$makefile"

  # 将 LINKAGE 改为 LINK_FILES
  sed -i 's|LINKAGE|LINK_FILES|g' "$makefile"

  echo "处理完成: $makefile"
done

echo "所有 Makefile 处理完成。"
