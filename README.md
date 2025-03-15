# 旧版本 openperf 在 xs-gem5 运行测试

仓库文件结构如下

```plaintext
.
├── Dockerfile      用于构建 Docker 镜像
├── Makefile        用于编译运行程序
├── README.md       仓库介绍
└── script          用于编译及适配调整的脚本
```

## 环境准备：docker

### 环境准备

首先运行脚本 `git clone` 项目所需仓库和设置环境变量

```bash
source script/env.sh
```

脚本会 clone NEMU am GEM5 至当前目录。并设置后续脚本运行过程中所需要的环境变量。具体内容可以查看 env.sh， 有一定注释。

docker安装可参考 [Docker 官方安装文档](https://docs.docker.com/engine/install/)

安装完成,执行`script/docker.sh`脚本,脚本将根据当前目录下 Dockerfile 构建镜像并启动新容器,详细可看脚本注释

```bash
./script/docker.sh
```

**重要提示**：

- 首次运行会耗时较长（需要构建镜像）
- 若修改了 Dockerfile 或项目代码，重新运行脚本即可更新环境
- 所有生成文件会保留在挂载目录中，不会因容器重启丢失

使用以下命令进入容器的交互式 shell：

```bash
docker compose exec openperf1 bash
```

## 在容器内借助香山的 am 和 NEMU 构建并运行 openperf 测试项目

### 程序适配

项目选用的并非最新的 openperf 版本，该版本 openperf 基于 “一生一芯” 环境中的 am 开发，与香山环境中 am 不完全相同，需要一定适配迁移。项目非常粗糙的进行了一定的适配，使得该版本的 openperf 得以在香山的 am 中得以成功编译及在 NEMU 上可以成功运行。

```bash
make fix # 调用脚本进行 openperf 适配
```

### 程序编译及测试执行

在适配修改完成后，将 openperf 所需编译测试项移动到 am 对应结构目录下，进行编译，并使用 NEMU 测试执行。

首先，在项目根目录运行以下指令编译香山配置的 NEMU，后续用于测试运行 openperf 测试项目

```bash
make nemu
```

而后，在项目根目录运行以下命令，该命令会将测试项及 openperf 带的依赖库移入 am 对应位置编译，并在 NEMU 上测试执行。

```bash
make nemu-linpack
```

成功后会出现测试结果的输出。通过修改`make nemu-linpack` 中的 `linpack` 相关字样来编译并测试执行不同的测试项目，注意，cpuemu 测试项暂时不可用。

## 在 gem5 上运行测试

```bash
./script/gem5.sh
```

首先，按上述操作运行脚本以编译 gem5，编译过程会花费一段时间，编译过程中在看到下列字样时按 enter 以继续：

```plaintext
You're missing the gem5 style or commit message hook. These hooks help
to ensure that your code follows gem5's style rules on git commit.
This script will now install the hook in your .git/hooks/ directory.
Press enter to continue, or ctrl-c to abort:
```

编译完成后，在项目根目录运行以下命令，该命令会将已经在 nemu 上成功编译运行的二进制文件在 xs-gem5 上运行。

```bash
make gem5-linpack
```

成功后会出现测试结果的输出。通过修改`make gem5-linpack` 中的 `linpack` 相关字样来编译并测试执行不同的测试项目，同样，cpuemu 测试项暂时不可用。
