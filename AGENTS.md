# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 macOS/Linux 开发环境自动化配置工具，按平台分流：

- **macOS**：Homebrew + `Brewfile` 安装 CLI；Volta、SDKMAN 管理运行时
- **Linux（含 root）**：apt/dnf/apk 装基础工具 + [mise](https://mise.jdx.dev) + `mise.toml` 装开发 CLI 和运行时（Node/Go/Python/Java）。Homebrew 在 root 下不可用，因此 Linux 路径不依赖 Homebrew

核心特性：

- **幂等性设计**：可重复运行 `install.sh` 而不破坏现有配置
- **模块化配置**：通过 `source` 加载 `dev-setup.zsh`，不覆盖用户的 `~/.zshrc`
- **智能 Kaku 集成**：自动检测 Kaku.app 并跳过插件重复安装，优化启动性能 80-120ms
- **软链接管理**：`.gitconfig`、`starship.toml`、`mise.toml` 通过软链接同步
- **中国大陆镜像**：macOS 自动切换 USTC 镜像；Linux 提示设置 `https_proxy` 或 `GITHUB_TOKEN`（可通过 `DEV_SETUP_CHINA_MIRROR=1/0` 覆盖）

## 核心命令

### 安装和验证

```bash
# 完整安装（macOS：Homebrew + Brewfile + Volta/SDKMAN；Linux：apt + mise）
./install.sh

# 测试配置加载
source ~/.zshrc

# 验证软链接
ls -la ~/.gitconfig ~/.config/starship.toml ~/.config/mise/config.toml

# 测试 Zsh 启动时间
time zsh -i -c exit
```

### 测试（Docker 隔离环境）

```bash
make lint              # ShellCheck 静态检查
make test              # 集成测试（普通用户路径，apt + mise）
make test-kaku         # Kaku 路径测试
make test-idempotent   # 幂等性测试
make test-root         # Root 路径测试（关键：验证 mise 在 root 下工作）
make test-all          # 全部
make build             # 仅构建 Docker 镜像
make clean             # 清理 Docker 镜像
```

### 维护工作流

```bash
# 同步本机 Homebrew 包到 repo
brew bundle dump --force

# 更新配置文件（已通过软链接自动同步）
# 直接编辑 dotfiles/ 下的文件即可

# 提交更改
git add Brewfile dotfiles/
git commit -m "chore: update configuration"
```

## 架构说明

### 配置加载流程

```
~/.zshrc
  └─> source dev-setup.zsh
        ├─> 基础环境（PATH, EDITOR）
        ├─> Oh My Zsh (plugins: git, npm, node, docker, python, docker-compose)
        ├─> 平台分流：
        │     ├─ macOS: Homebrew 镜像 + brew shellenv（中国大陆切 USTC）
        │     └─ Linux: eval "$(mise activate zsh)"
        ├─> 别名（podman→docker, code-insiders→code, python→python3 等）
        ├─> CLI 工具初始化（fzf, zoxide, yazi, thefuck 懒加载）
        ├─> 包管理器（macOS: Volta + SDKMAN；双平台：pnpm + bun + Go）
        └─> 检测 Kaku 是否存在
              ├─> 存在: source ~/.config/kaku/zsh/kaku.zsh (Kaku 管理插件+Starship+别名+历史)
              └─> 不存在: 手动初始化 Starship, 插件, 历史, 补全, git 别名
```

### Kaku 集成逻辑

**关键设计**：避免 Oh My Zsh 和 Kaku 重复加载相同插件

- `install.sh` 检测 `~/.config/kaku/zsh/kaku.zsh` 是否存在
  - 存在：跳过插件安装（由 Kaku 管理）
  - 不存在：安装插件到 `~/.oh-my-zsh/custom/plugins/`
- `dev-setup.zsh` 运行时检测 Kaku
  - 存在：`source kaku.zsh`（Kaku 提供 Starship + 插件）
  - 不存在：手动初始化 Starship 和插件

**性能优化**：

- Oh My Zsh 设置 `ZSH_THEME=""` 禁用主题（避免与 Starship 冲突）
- 插件列表仅保留 Oh My Zsh 独有的（git, npm, node, docker, python, docker-compose）
- 移除 `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-completions`（由 Kaku 管理）

### 软链接管理

```bash
# install.sh 创建的软链接
~/.gitconfig                 -> /path/to/dev-setup/dotfiles/.gitconfig
~/.config/starship.toml      -> /path/to/dev-setup/dotfiles/starship.toml
~/.config/mise/config.toml   -> /path/to/dev-setup/mise.toml          # 仅 Linux

# dev-setup.zsh 通过 source 加载（非软链接）
# 在 ~/.zshrc 中追加: source "/path/to/dev-setup/dotfiles/dev-setup.zsh"
```

## 修改配置文件时的注意事项

### 修改 dev-setup.zsh

- **PATH 顺序**：`$HOME/.local/bin` 优先级最高，避免系统工具被覆盖（mise 也在此目录）
- **平台分流**：Homebrew 块仅 `[[ "$OSTYPE" == darwin* ]]` 生效；mise activate 仅 `[[ "$OSTYPE" == linux* ]]` 生效
- **条件加载**：所有可选工具（bun, pnpm, SDKMAN）都需检查文件是否存在
- **Kaku 检测**：必须保持 `if [[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]]` 逻辑

### 修改 install.sh

- **幂等性**：使用 `if [[ ! -d ... ]]` / `command -v` 检查避免重复安装
- **追加模式**：使用 `grep -q` 检查 `~/.zshrc` 是否已包含配置
- **平台分流**：Darwin 走 Homebrew；Linux 走 `_install_base_linux` + mise
- **Root 阻断**：仅在 macOS 阻断 root；Linux 路径明确支持 root
- **CI 模式**：末尾 `exec zsh -l` 在 `CI=true` 或 `DEV_SETUP_NO_EXEC=1` 时跳过
- **Kaku 检测**：在安装插件前检查 `$HOME/.config/kaku/zsh/kaku.zsh`

### 修改 Brewfile / mise.toml

- **Brewfile**（macOS）：修改后运行 `brew bundle dump --force`
- **mise.toml**（Linux）：优先使用 `aqua:` 或 `ubi:` 后端，避免 cargo 编译。修改后 `mise install` 应用

## 常见问题

### Zsh 启动慢

1. 检查是否重复加载插件：`echo $fpath | tr ' ' '\n' | grep -E '(autosuggestions|syntax-highlighting)'`
2. 确认 Kaku 检测逻辑正确：`[[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]] && echo "Kaku detected"`
3. 清理工具初始化缓存：`dev-setup-clear-cache`（清除 fzf/zoxide/starship 缓存文件）
4. 参考 `docs/zsh-optimization.md`

### 软链接失效

```bash
# 重新创建软链接
ln -sf "$(pwd)/dotfiles/.gitconfig" ~/.gitconfig
ln -sf "$(pwd)/dotfiles/starship.toml" ~/.config/starship.toml
```

## 文件结构

```
dev-setup/
├── install.sh              # 主安装脚本（macOS → Homebrew；Linux → apt + mise）
├── Brewfile                # macOS 软件清单
├── mise.toml               # Linux 工具清单（软链接到 ~/.config/mise/config.toml）
├── Makefile                # 测试命令入口（make test-all / make test-root）
├── Dockerfile              # Docker 测试环境（Ubuntu 24.04，testuser + root 双路径）
├── dotfiles/
│   ├── dev-setup.zsh      # 统一环境配置（按平台分流加载 Homebrew / mise）
│   ├── .gitconfig         # Git 配置（软链接到 ~/.gitconfig）
│   └── starship.toml      # Starship 配置（软链接到 ~/.config/starship.toml）
├── scripts/
│   ├── test-install.sh    # 集成测试（按 OS 分支验证）
│   └── test-idempotent.sh # 幂等性测试
└── docs/
    ├── zsh-optimization.md # Kaku 集成优化说明
    └── testing.md          # 测试架构文档
```

## 语言约定

- 用户文档（README.md, CHANGELOG.md）使用简体中文
- 代码注释使用简体中文
- Git commit 消息使用英文（遵循 Conventional Commits）
