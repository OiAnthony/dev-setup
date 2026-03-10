# Ubuntu 24.04 基础镜像
FROM ubuntu:24.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    zsh \
    sudo \
    locales \
    file \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 设置 locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 创建非 root 用户（Homebrew 要求）
RUN useradd -m -s /bin/zsh testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 切换到测试用户
USER testuser
WORKDIR /home/testuser

# 预装 Homebrew（独立层，优化缓存）
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 配置 Homebrew 环境变量
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# === 关键优化：先复制 Brewfile，预安装包 ===
COPY --chown=testuser:testuser Brewfile /home/testuser/dev-setup/Brewfile
ENV HOMEBREW_NO_AUTO_UPDATE=1
RUN brew bundle --file=/home/testuser/dev-setup/Brewfile || true

# 复制项目文件（Brewfile 已缓存，其他文件变更不影响上层）
COPY --chown=testuser:testuser . /home/testuser/dev-setup

WORKDIR /home/testuser/dev-setup

# 设置默认命令
CMD ["/bin/zsh"]
