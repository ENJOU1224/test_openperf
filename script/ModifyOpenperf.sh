#!/bin/bash

# 为openperf的common文件夹下的Makefile适配香山AM,包括增加LIBS += klib和将include的Makefile改为Makefile.lib
target_dir="${T1_HOME}/openperf/src/common"

# 检查目标目录是否存在
if [ ! -d "$target_dir" ]; then
  echo "错误：目录不存在 $target_dir" >&2
  exit 1
fi

# 遍历所有子目录
for dir in "$target_dir"/*/; do
  makefile="${dir}Makefile"
  
  # 检查Makefile是否存在
  if [ ! -f "$makefile" ]; then
    echo "警告：跳过无Makefile的目录 ${dir}" >&2
    continue
  fi

  # 检查是否已包含目标行
  if grep -q '^[[:space:]]*LIBS[[:space:]]*+=[[:space:]]*.*klib' "$makefile"; then
    echo "已存在：$makefile"
  else
    # 追加内容并处理错误
    if ! echo "LIBS += klib" >> "$makefile"; then
      echo "错误：写入失败 $makefile" >&2
      exit 1
    fi
    echo "已修改：$makefile"
  fi

  # 检查是否有 include $(AM_HOME)/Makefile，并修改为 include $(AM_HOME)/Makefile.lib
  if grep -q '^[[:space:]]*include[[:space:]]*\$(AM_HOME)/Makefile$' "$makefile"; then
    # 使用 sed 替换
    if sed -i 's|^\([[:space:]]*include[[:space:]]*\$(AM_HOME)/Makefile\)$|\1.lib|' "$makefile"; then
      echo "已修改：$makefile 中的 include \$(AM_HOME)/Makefile -> include \$(AM_HOME)/Makefile.lib"
    else
      echo "错误：修改失败 $makefile" >&2
      exit 1
    fi
  else
    echo "未找到：$makefile 中的 include \$(AM_HOME)/Makefile"
  fi
done
