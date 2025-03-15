FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV GEM5_HOME=/home/openperf/GEM5
ENV PATH="${GEM5_HOME}/build/X86:${PATH}"

# 创建用户并安装依赖
RUN apt-get update && \
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
        wget \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

# 创建与宿主机匹配的用户
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g $GROUP_ID openperf && \
    useradd -u $USER_ID -g $GROUP_ID -m openperf 

# 切换到 openperf 用户
USER openperf
WORKDIR /home/openperf

RUN echo 'source /home/openperf/script/env.sh' >> /home/openperf/.bashrc

# 设置默认命令为 Bash
CMD ["/bin/bash"]
