FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV GEM5_HOME=/home/openperf/GEM5
ENV PATH="${GEM5_HOME}/build/X86:${PATH}"

# 创建用户并安装依赖
RUN useradd -m -u 1001 openperf && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc-riscv64-linux-gnu \
        libc6-dev-riscv64-cross \
        build-essential \
        clang \
        bear \
        git \
        m4 \
        scons \
        zlib1g \
        zlib1g-dev \
        libprotobuf-dev \
        protobuf-compiler \
        libprotoc-dev \
        libgoogle-perftools-dev \
        python3-dev \
        libboost-all-dev \
        pkg-config \
        libsqlite3-dev \
        zstd \
        libzstd-dev \
        cmake \
        vim \
        bison \
        flex \
        libsdl2-dev \
        libreadline-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 切换到 openperf 用户
USER openperf
WORKDIR /home/openperf

# 复制源代码和构建脚本
COPY --chown=openperf:openperf script /home/openperf/script
COPY --chown=openperf:openperf Makefile /home/openperf/Makefile

# 设置默认命令为 Bash
CMD ["/bin/bash"]
