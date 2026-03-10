# 开发环境自动化配置

快速在新 macOS 或 Linux（Ubuntu）机器上还原开发环境。支持 Oh My Zsh + Kaku 双系统优化，启动性能提升 80-120ms。

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

### 核心工具（Brewfile 自动安装）

**版本控制**：

- Git + GitHub CLI (gh)
- git-delta（更好的 diff 显示，集成到 .gitconfig）
- lazygit（Git TUI）
- gitsu（Git 用户切换）

**编程语言**：

- Node.js
- Python 3.14 + uv（现代 Python 包管理器）
- Go

**Shell 增强**：

- Starship（自定义提示符，极简配置）
- zoxide（智能目录跳转，`cd` 替代）
- fzf（模糊查找 + 自定义 `fzf-cd` 函数）
- fd（更快的 find）
- ripgrep（更快的 grep）

**系统工具**：

- htop / btop（系统监控）
- curl / wget（下载工具）
- vim / neovim（编辑器，默认 EDITOR=nvim）
- tree（目录树）
- jq（JSON 处理）

### 可选工具（交互式安装）

- Bun（JavaScript 运行时）
- pnpm（Node.js 包管理器）
- SDKMAN（Java 版本管理）
- podman（Docker 替代品，需取消注释 Brewfile）

## 配置文件说明

本项目采用模块化配置，核心文件通过 `source` 加载而非覆盖 `~/.zshrc`：

- `dev-setup.zsh`：统一的开发环境配置（PATH、别名、工具初始化）
  - 自动检测并集成 Kaku（如已安装）
  - 包含 Oh My Zsh、fzf、zoxide、yazi 等工具配置
  - 内置 pnpm、bun、SDKMAN、Android SDK、Go 等环境变量
- `.gitconfig`：Git 配置（delta diff、zdiff3 合并、常用别名）
- `starship.toml`：Starship 提示符配置（极简单行风格）

### 内置别名

| 别名 | 实际命令 | 说明 |
|------|---------|------|
| `docker` | `podman` | 使用 podman 替代 docker |
| `code` | `code-insiders` | VS Code Insiders |
| `python` | `python3` | Python 3 |
| `oc` | `opencode` | OpenCode CLI |
| `y` | yazi 函数 | 文件管理器（支持 cd 跟随） |

### Kaku 集成

如已安装 [Kaku.app](https://kaku.app)，配置会自动优化：

- 插件由 Kaku 统一管理（syntax-highlighting、autosuggestions、completions）
- 避免与 Oh My Zsh 重复加载，启动速度提升 80-120ms
- 详见 [docs/zsh-optimization.md](docs/zsh-optimization.md)

## 首次使用指南

1. **修改 Git 用户信息**：

   ```bash
   vim ~/.gitconfig
   # 修改 user.name 和 user.email
   ```

2. **重新加载配置**：

   ```bash
   source ~/.zshrc
   ```

## 维护

### 同步本机环境到 repo

```bash
# 更新 Brewfile
brew bundle dump --force

# 提交更改（配置文件已通过软链接自动同步）
git add Brewfile
git commit -m "chore: update Brewfile"
git push
```

### 添加新工具

```bash
brew install 新工具名
brew bundle dump --force
git commit -am "feat: add 新工具名"
git push
```

### 更新配置文件

编辑 `dotfiles/dev-setup.zsh` 或其他配置文件，然后提交：

```bash
git commit -am "chore: update dev-setup configuration"
git push
```

## 项目结构

```
dev-setup/
├── install.sh              # 主安装脚本（智能检测 Kaku）
├── Brewfile                # 软件清单（Homebrew Bundle）
├── dotfiles/               # 配置文件
│   ├── dev-setup.zsh      # 统一环境配置（通过 source 加载）
│   ├── .gitconfig         # Git 配置（软链接到 ~/.gitconfig）
│   └── starship.toml      # Starship 配置（软链接到 ~/.config/starship.toml）
├── docs/                   # 文档
│   ├── zsh-optimization.md # Zsh 性能优化说明
│   └── tech-stack.mdx      # 技术栈说明
└── README.md
```

## 特性

- ✅ 跨平台支持（macOS + Linux Ubuntu）
- ✅ 幂等性设计（可重复运行）
- ✅ 智能 Kaku 集成（自动检测并优化）
- ✅ 模块化配置（通过 source 加载，不覆盖现有 .zshrc）
- ✅ 软链接管理（配置文件自动同步）
- ✅ 交互式可选工具安装

## 测试

项目包含自动化测试，验证安装脚本在干净环境下的正确性。

### 本地测试

```bash
# 安装 ShellCheck（如果未安装）
brew install shellcheck

# 静态检查
make lint

# 运行所有测试（需要 Docker）
make test-all

# 单独运行测试
make test              # 集成测试
make test-kaku         # Kaku 路径测试
make test-idempotent   # 幂等性测试
```

### CI/CD

GitHub Actions 会在每次 push 或 PR 时自动运行：
- ShellCheck 静态检查
- Docker 容器集成测试
- Kaku 检测逻辑验证
- 幂等性验证

## 注意事项

- 使用 Homebrew 统一管理软件包
- **不要提交敏感信息**（SSH 私钥、API token、密码等）
- 首次使用需修改 `.gitconfig` 中的用户名和邮箱
- `install.sh` 采用追加模式，不会覆盖现有 `~/.zshrc` 内容
