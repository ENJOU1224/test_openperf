##! /usr/bin/env bash

# 需要修改的文件路径（请替换为实际路径）
TARGET_FILE="$GEM5/configs/example/xiangshan.py"

cp $SCRIPT_HOME/cpu_params_profiles.py $GEM5/configs/example

# 添加顶部import（只在不存在时添加）
if ! grep -q "from cpu_params_profiles import param_profiles" "$TARGET_FILE"; then
    sed -i '1i from cpu_params_profiles import param_profiles' "$TARGET_FILE"
    echo "[已添加] 成功插入导入语句"
else
    echo "[跳过] 检测到已有导入语句"
fi

# 在ideal_kmhv3块后添加配置代码（只在不存在时添加）
if ! grep -q "cpu_profile" "$TARGET_FILE"; then
    sed -i '/ideal_kmhv3/{:a;n;/^[[:space:]]*$/!ba;i\
    if args.cpu_profile in param_profiles:\
        print(f"Applying CPU profile: {args.cpu_profile}")\
        param_profiles[args.cpu_profile](args, test_sys)\
    else:\
        print("Using default CPU parameters")
}' "$TARGET_FILE"
    echo "[已添加] 配置代码块插入成功"
else
    echo "[跳过] 检测到已有配置代码块"
fi

# 需要修改的文件路径（请替换为实际路径）
TARGET_FILE="$GEM5/configs/common/Options.py"

# 添加顶部import（只在不存在时添加）
if ! grep -q "from cpu_params_profiles import param_profiles" "$TARGET_FILE"; then
    sed -i '1i from cpu_params_profiles import param_profiles' "$TARGET_FILE"
    echo "[已添加] 成功插入导入语句"
else
    echo "[跳过] 检测到已有导入语句"
fi

# 检查是否已存在--cpu-profile参数（修复grep参数解析问题）
if ! grep -q -- "--cpu-profile" "$TARGET_FILE"; then
    # 使用sed在--ideal-kmhv3参数后插入新配置
    sed -i '/help="Use KunminghuV3 ideal params, which take priority over command-line arguments.")/a \
    parser.add_argument("--cpu-profile", type=str, choices=param_profiles.keys(),\
                      help="选择CPU参数配置集: %s" % list(param_profiles.keys()))' "$TARGET_FILE"

    echo "[已添加] 成功插入CPU配置集参数"
else
    echo "[跳过] 检测到已有--cpu-profile参数"
fi
