#!/bin/bash

# 标记是否有环境变量未设置
env_vars_missing=false
missing_vars_message=""

# 检测环境变量
if [ -z "${UID}" ]; then
    missing_vars_message+="UID "
    env_vars_missing=true
fi
if [ -z "${GID}" ]; then
    missing_vars_message+="GID "
    env_vars_missing=true
fi
if [ -z "${T1_HOME}" ]; then
    missing_vars_message+="T1_HOME "
    env_vars_missing=true
fi

# 如果有任何环境变量未设置，则打印提示并退出
if [ "$env_vars_missing" = true ]; then
    echo "---------------------------------------------------------------------"
    echo "错误: 环境变量 (${missing_vars_message% }) 未定义。"
    echo "请先执行: source script/env.sh"
    echo "---------------------------------------------------------------------"
    exit 1
fi

# 如果所有环境变量都已设置，则直接执行 docker compose 命令
# 停止并删除旧容器 (如果存在)
docker compose down

# 构建并以守护进程模式启动容器
docker compose up -d --build

