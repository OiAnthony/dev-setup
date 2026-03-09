# 开发环境自动化还原

快速在新 macOS 或 Linux（Ubuntu）机器上还原开发环境。

## 快速开始

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/你的用户名/dev-setup/main/install.sh | bash
```

### 克隆后安装

```bash
git clone https://github.com/你的用户名/dev-setup.git
cd dev-setup
chmod +x install.sh
./install.sh
```

安装完成后运行：

```bash
source ~/.zshrc
```

## 包含的工具

### 核心工具（自动安装）

**版本控制**：
- Git + GitHub CLI (gh)
- git-delta（更好的 diff 显示）
- lazygit（Git TUI）
- gitsu（Git 用户切换）

**编程语言**：
- Node.js
- Python 3.14
- Go

**Shell 增强**：
- Starship（自定义提示符）
- zoxide（智能目录跳转）
- fzf（模糊查找）
- fd（更快的 find）
- ripgrep（更快的 grep）

**系统工具**：
- htop / btop（系统监控）
- curl / wget（下载工具）
- vim / neovim（编辑器）
- tree（目录树）
- jq（JSON 处理）

### 可选工具（交互式安装）

- Bun（JavaScript 运行时）
- pnpm（Node.js 包管理器）
- SDKMAN（Java 版本管理）
- podman（Docker 替代品，需手动取消注释 Brewfile）
- uv（Python 包管理器，需手动取消注释 Brewfile）


## 配置文件说明

本项目包含以下配置文件：

- `.zshrc`：Shell 配置（Oh My Zsh、插件、别名、工具初始化）
- `.gitconfig`：Git 配置（需修改用户信息）
- `starship.toml`：Starship 提示符配置（可选启用）

## 首次使用指南

1. **修改 Git 用户信息**：
   ```bash
   vim ~/.gitconfig
   # 修改 user.name 和 user.email
   ```

2. **启用 Starship 提示符**（可选）：
   ```bash
   vim ~/.zshrc
   # 取消注释 Starship 相关行
   ```

3. **重新加载配置**：
   ```bash
   source ~/.zshrc
   ```

## 维护

### 同步本机环境到 repo

```bash
# 更新 Brewfile
brew bundle dump --force

# 备份配置文件
cp ~/.zshrc dotfiles/.zshrc
cp ~/.gitconfig dotfiles/.gitconfig
cp ~/.config/starship.toml dotfiles/starship.toml

# 提交更改
git add .
git commit -m "Update environment configuration"
git push
```

### 添加新工具

```bash
brew install 新工具名
brew bundle dump --force
git commit -am "Add 新工具名"
git push
```

### 更新配置文件

编辑 `dotfiles/.zshrc`，然后提交：

```bash
git commit -am "Update zshrc"
git push
```

## 项目结构

```
dev-setup/
├── install.sh           # 主安装脚本
├── Brewfile             # 软件清单
├── dotfiles/            # 配置文件
│   ├── .zshrc          # Shell 配置
│   ├── .gitconfig      # Git 配置
│   └── starship.toml   # Starship 配置
├── docs/                # 文档
│   └── tech-stack.mdx  # 技术栈说明
└── README.md
```

## 注意事项

- 支持 macOS 和 Linux（Ubuntu）
- 使用 Homebrew 统一管理软件包
- 可重复运行 install.sh（幂等性）
- 不要提交敏感信息（SSH 私钥、API token）
- 首次使用需修改 .gitconfig 中的用户信息
