# Ubuntu 24.04 基础镜像
# 用于在隔离环境中验证 install.sh 的 Linux 路径（普通用户 + root）
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 仅安装最少的引导依赖：install.sh 自身需要 curl/git/sudo/ca-certificates，
# 其余基础工具由 install.sh 通过 apt 安装。
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    ca-certificates \
    locales \
    file \
    procps \
    && rm -rf /var/lib/apt/lists/*

# locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 创建非 root 测试用户（用于 make test / make test-kaku / make test-idempotent）
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 复制项目文件到固定位置；测试在 / dev-setup 下进行
# - testuser: /dev-setup 由 root 拥有但全局可读；测试时由 testuser 在 $HOME 下 ln -s
# - root:    直接使用 /dev-setup
COPY . /opt/dev-setup
RUN chown -R testuser:testuser /opt/dev-setup

# 默认以 testuser 运行；root 路径通过 docker run -u 0 覆盖
USER testuser
WORKDIR /home/testuser

# 入口为脚本：测试时由 docker run 指定具体测试脚本
CMD ["/bin/bash"]
