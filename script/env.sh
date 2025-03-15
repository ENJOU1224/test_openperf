#! /usr/bin/env bash

git clone https://github.com/OpenXiangShan/nexus-am.git --filter=tree:0
git clone https://github.com/OpenXiangShan/NEMU.git --filter=tree:0
git clone -b origin/main https://github.com/OSCPU/openperf.git --filter=tree:0
git clone https://github.com/OpenXiangshan/GEM5.git  --filter=tree:0
wget  -nc https://github.com/OpenXiangShan/GEM5/releases/download/2024-10-16/riscv64-nemu-interpreter-c1469286ca32-so

export T1_HOME=$PWD                                                     # 根目录
export AM_HOME=$PWD/nexus-am                                            # AM
export GEM5=$PWD/GEM5                                                   # GEM5
export OPENPERF_HOME=$PWD/openperf                                      # OPENPERF
export NEMU_HOME=$PWD/NEMU                                              # NEMU
export SCRIPT_HOME=$PWD/script                                          # 脚本目录
export LINUX_GNU_TOOLCHAIN=1                                            # 将此变量设为 1 以让 workload 编译时使用通过 apt 安装的交叉编译工具链，若未设为 1 则依赖自行编译工具链
export GCBV_REF_SO=$T1_HOME/riscv64-nemu-interpreter-c1469286ca32-so    # GEM5 运行过程中 difftest 使用的NEMU静态对象 
export UID=$(id -u)  # 获取当前用户ID
export GID=$(id -g)  # 获取当前用户组ID
