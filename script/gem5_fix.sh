#!/bin/bash

file_path="$GEM5/configs/common/FSConfig.py"  

# 检查是否已插入过
if grep -q "RiscvRTC" "$file_path"; then
    exit 0
fi

# 检查目标行是否存在
if ! grep -q "self.lint.num_threads = np" "$file_path"; then
    echo "Error: Target line not found in $file_path" >&2
    exit 1
fi

# 提取缩进和行号
indent=$(sed -n 's/^\([[:space:]]*\)self.lint.num_threads = np.*/\1/p' "$file_path")
line_number=$(grep -n "self.lint.num_threads = np" "$file_path" | cut -d: -f1)

# 使用awk安全插入内容
awk -v line_num="$line_number" -v indent="$indent" '
    NR == line_num {
        print $0
        print indent "self.rtc = RiscvRTC(frequency=Frequency(\"100MHz\"))"
        print indent "self.lint.int_pin = self.rtc.int_pin"
        next
    }
    { print }
' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
