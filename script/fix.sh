#! /usr/bin/env bash
$SCRIPT_HOME/ModifyOpenperf.sh  # 为openperf中的库的Makefile针对香山am做适配
$SCRIPT_HOME/ioe.sh             # 将部分测试项目中ioe_init的函数名调整为香山am中的_ioe_init
$SCRIPT_HOME/putch.sh           # 将openperf中的putch函数名调整为香山am中的对应函数名 
$SCRIPT_HOME/strchr.sh          # 将openperf中定义的strchr名称调整，以避免与香山am中同名函数冲突，使用openperf自定义函数
$SCRIPT_HOME/strrchr.sh         # 将openperf中定义的strrchr名称调整，以避免与香山am中同名函数冲突，使用openperf自定义函数
$SCRIPT_HOME/uptimes.sh         # 调整openperf中uptime函数名，以使用openperf自定义uptime函数
$SCRIPT_HOME/PATH_TO_DIR.sh     # 将openperf中所有makefile中的PATH变量改为香山am中使用的DIR变量
$SCRIPT_HOME/ldecod.sh          # 删掉openperf中未用到的ldecod库
$SCRIPT_HOME/soft-fp.sh         # 删掉openperf中重复定义的FP_HANDLE_EXCEPTIONS
$SCRIPT_HOME/sprintf.sh         # 删掉未实现的将 sprintf define为 mysprintf
$SCRIPT_HOME/bench1.sh          # 调整uptimes函数的实现，以适配香山am
$SCRIPT_HOME/makefile.sh        # 将openperf所有测试项目的Makefile 针对香山am做调整
$SCRIPT_HOME/tcc.sh             # 
$SCRIPT_HOME/bool.sh            # 为使用到bool变量类型的测试项目增加stdbool的include
$SCRIPT_HOME/stdio.sh           # 删除mcf.c中对stdio.h的include
$SCRIPT_HOME/makefile.sh        # 前面的makefile.sh不知道为啥执行一遍会执行不干净，执行两遍就可以了
$SCRIPT_HOME/bs_realign.sh      # 调整x264中bs_realign的实现来避免编译werror
$SCRIPT_HOME/libgcc.sh          # 将自己实现的clz和ctz函数放入依赖其的soft-fp库中
$SCRIPT_HOME/osdep.sh           # 调整x264，使其使用x264自己实现的x264_clz 和 x264_ctz函数
$SCRIPT_HOME/maxinst.sh         # 调整gem5最大指令数限制保证可以跑完x264测试
$SCRIPT_HOME/InsertTestPara.sh  # 在gem5里插入测试用参数函数相关内容
