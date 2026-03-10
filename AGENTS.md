# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 macOS/Linux 开发环境自动化配置工具，通过 Homebrew Bundle 和模块化 Zsh 配置快速还原开发环境。核心特性：

- **幂等性设计**：可重复运行 `install.sh` 而不破坏现有配置
- **模块化配置**：通过 `source` 加载 `dev-setup.zsh`，不覆盖用户的 `~/.zshrc`
- **智能 Kaku 集成**：自动检测 Kaku.app 并跳过插件重复安装，优化启动性能 80-120ms
- **软链接管理**：配置文件通过软链接同步，修改后自动反映到 repo

## 核心命令

### 安装和测试
```bash
# 完整安装（会提示可选工具）
./install.sh

# 测试配置加载
source ~/.zshrc

# 验证软链接
ls -la ~/.gitconfig ~/.config/starship.toml

# 测试 Zsh 启动时间
time zsh -i -c exit
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
        ├─> Oh My Zsh (plugins: git, npm, node, docker, python, docker-compose)
        ├─> 检测 Kaku 是否存在
        │     ├─> 存在: source ~/.config/kaku/zsh/kaku.zsh (Kaku 管理插件)
        │     └─> 不存在: 手动加载 zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions
        ├─> fzf, zoxide, yazi 初始化
        └─> 环境变量 (pnpm, bun, SDKMAN, Android SDK, Go)
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
~/.gitconfig -> /path/to/dev-setup/dotfiles/.gitconfig
~/.config/starship.toml -> /path/to/dev-setup/dotfiles/starship.toml

# dev-setup.zsh 通过 source 加载（非软链接）
# 在 ~/.zshrc 中追加: source "/path/to/dev-setup/dotfiles/dev-setup.zsh"
```

## 修改配置文件时的注意事项

### 修改 dev-setup.zsh
- **PATH 顺序**：`$HOME/.local/bin` 优先级最高，避免系统工具被覆盖
- **条件加载**：所有可选工具（bun, pnpm, SDKMAN）都需检查文件是否存在
- **Kaku 检测**：必须保持 `if [[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]]` 逻辑

### 修改 install.sh
- **幂等性**：使用 `if [[ ! -d ... ]]` 检查避免重复安装
- **追加模式**：使用 `grep -q` 检查 `~/.zshrc` 是否已包含配置
- **Kaku 检测**：在安装插件前检查 `$HOME/.config/kaku/zsh/kaku.zsh`

### 修改 Brewfile
- **注释可选工具**：如 `# brew "podman"` 需用户手动取消注释
- **同步命令**：修改后运行 `brew bundle dump --force` 覆盖

### 修改 .gitconfig
- **占位符**：保留 `Your Name` 和 `your.email@example.com` 提示用户修改
- **delta 配置**：`side-by-side = true` 依赖终端宽度，窄屏用户可能需调整

## 常见问题

### Zsh 启动慢
1. 检查是否重复加载插件：`echo $fpath | tr ' ' '\n' | grep -E '(autosuggestions|syntax-highlighting)'`
2. 确认 Kaku 检测逻辑正确：`[[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]] && echo "Kaku detected"`
3. 参考 `docs/zsh-optimization.md`

### 软链接失效
```bash
# 重新创建软链接
ln -sf "$(pwd)/dotfiles/.gitconfig" ~/.gitconfig
ln -sf "$(pwd)/dotfiles/starship.toml" ~/.config/starship.toml
```

### 可选工具未安装
- Bun: `curl -fsSL https://bun.sh/install | bash`
- pnpm: `curl -fsSL https://get.pnpm.io/install.sh | sh -`
- SDKMAN: `curl -s "https://get.sdkman.io" | bash`

## 文件结构

```
dev-setup/
├── install.sh              # 主安装脚本（检测 Kaku，创建软链接）
├── Brewfile                # Homebrew 软件清单
├── dotfiles/
│   ├── dev-setup.zsh      # 统一环境配置（通过 source 加载）
│   ├── .gitconfig         # Git 配置（软链接到 ~/.gitconfig）
│   └── starship.toml      # Starship 配置（软链接到 ~/.config/starship.toml）
└── docs/
    └── zsh-optimization.md # Kaku 集成优化说明
```

## 语言约定

- 用户文档（README.md, CHANGELOG.md）使用简体中文
- 代码注释使用简体中文
- Git commit 消息使用英文（遵循 Conventional Commits）
