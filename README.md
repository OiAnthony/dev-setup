# 开发环境自动化配置

快速在新 macOS 或 Linux（Ubuntu/Debian/Fedora/Alpine 等）机器上还原开发环境。支持 Oh My Zsh + Kaku 双系统优化，启动性能提升 80-120ms。中国大陆网络自动切换 USTC 镜像加速（macOS）。

> **平台策略**
> - **macOS**：使用 Homebrew + `Brewfile` 安装所有 CLI 工具，配合 Volta、SDKMAN 管理运行时。
> - **Linux（含 root）**：使用系统包管理器（apt/dnf/apk）安装基础工具，使用 [mise](https://mise.jdx.dev) 通过 `mise.toml` 安装开发 CLI 与运行时（Node/Go/Python/Java）。**Homebrew 在 root 下不可用**，因此 Linux 路径不依赖 Homebrew。

## 快速开始

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

### 克隆后安装

```bash
git clone https://github.com/OiAnthony/dev-setup.git
cd dev-setup
chmod +x install.sh
./install.sh
```

安装完成后运行：

```bash
source ~/.zshrc
```

## 包含的工具

### macOS（Brewfile）

详见 [`Brewfile`](Brewfile)。包含 git/gh/lazygit/git-delta、starship/fzf/zoxide/fd/ripgrep、neovim/htop/btop/jq、python@3.14/go/uv，以及 Maple Mono / JetBrains Mono Nerd Font。

### Linux（apt + mise）

**apt/dnf/apk 装基础系统工具**：`git curl wget vim zsh zip unzip tree htop jq build-essential`

**[mise](https://mise.jdx.dev) 装开发 CLI 与运行时**（详见 [`mise.toml`](mise.toml)）：

- CLI：starship、fzf、zoxide、fd、ripgrep、gh、lazygit、git-delta、neovim、btop、yazi
- 运行时：Node.js（替代 Volta）、Go、Python、uv、Java（替代 SDKMAN）
- 后端优先 `aqua:` / `ubi:`（GitHub release 预编译二进制，无需编译工具链，root 友好）

### 自动安装（双平台）

- **Bun**：JavaScript 运行时（官方安装脚本）
- **pnpm**：Node.js 包管理器（官方安装脚本）
- **Oh My Zsh** + Zsh 插件（git clone）

### macOS 独有

- **Volta**：Node.js 版本管理器（Linux 由 mise 接管）
- **SDKMAN**：Java/Kotlin/Scala 版本管理器（Linux 由 mise 提供 `java`）

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
| `docker` | `podman` | 使用 podman 替代 docker（如已安装） |
| `code` | `code-insiders` | VS Code Insiders（如已安装） |
| `python` | `python3` | Python 3 |
| `pip` | `pip3` | Python 3 包管理器 |
| `cc` | `claude` | Claude Code CLI |
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

**macOS（Brewfile）**：

```bash
brew bundle dump --force
git add Brewfile
git commit -m "chore: update Brewfile"
git push
```

**Linux（mise.toml）**：

```bash
# 编辑仓库根目录的 mise.toml 增删工具，然后：
mise install
git add mise.toml
git commit -m "chore: update mise tool list"
git push
```

### 添加新工具

- macOS：`brew install <name>` 后 `brew bundle dump --force`
- Linux：在 `mise.toml` 中加一行（优先 `aqua:`/`ubi:` 后端），运行 `mise install`

### 更新配置文件

编辑 `dotfiles/dev-setup.zsh` 或其他配置文件，然后提交：

```bash
git commit -am "chore: update dev-setup configuration"
git push
```

## 项目结构

```
dev-setup/
├── install.sh              # 主安装脚本（macOS → Homebrew；Linux → apt + mise）
├── Brewfile                # macOS 软件清单（Homebrew Bundle）
├── mise.toml               # Linux 工具清单（mise，软链接到 ~/.config/mise/config.toml）
├── Makefile                # 测试命令入口（make test-all / make test-root）
├── Dockerfile              # Docker 测试环境（Ubuntu 24.04，覆盖 testuser + root 双路径）
├── CLAUDE.md               # Claude Code 项目指南
├── AGENTS.md               # 同 CLAUDE.md（兼容性）
├── dotfiles/               # 配置文件
│   ├── dev-setup.zsh      # 统一环境配置（按平台分流加载 Homebrew / mise）
│   ├── .gitconfig         # Git 配置（软链接到 ~/.gitconfig）
│   └── starship.toml      # Starship 配置（软链接到 ~/.config/starship.toml）
├── scripts/                # 测试脚本
│   ├── test-install.sh    # 集成测试（按 OS 分支验证）
│   └── test-idempotent.sh # 幂等性测试
└── docs/                   # 文档
    ├── zsh-optimization.md # Zsh 性能优化说明
    └── testing.md          # 测试架构文档
```

## 特性

- ✅ 跨平台（macOS + Linux Ubuntu/Debian/Fedora/Alpine）
- ✅ **Linux root 用户支持**（通过 mise，绕开 Homebrew 限制）
- ✅ 幂等性设计（可重复运行）
- ✅ 智能 Kaku 集成（自动检测并优化）
- ✅ 模块化配置（通过 source 加载，不覆盖现有 .zshrc）
- ✅ 软链接管理（配置文件自动同步）
- ✅ 中国大陆镜像加速（macOS 自动切 USTC；Linux 提示走 `https_proxy` / `GITHUB_TOKEN`）
- ✅ Docker 隔离测试（普通用户 + root 双路径）

## 在 Linux 服务器（含 root）使用

```bash
# 直接以 root 一键安装
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

中国大陆环境建议先设置代理：

```bash
export https_proxy=http://127.0.0.1:7890
# 或使用 GITHUB_TOKEN 提高 release 限流
export GITHUB_TOKEN=ghp_xxx
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

mise 管理的工具不一定出现在裸 PATH 中，使用 `mise activate`（已在 `dev-setup.zsh` 中自动 eval）后或通过 `mise exec -- <cmd>` 调用。常用命令：

```bash
mise ls                    # 列出已安装版本
mise use --global node@22  # 全局切换 Node.js 版本
mise install               # 按 mise.toml 安装/更新所有工具
```

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
make test              # 集成测试（普通用户 / Linux）
make test-kaku         # Kaku 路径测试
make test-idempotent   # 幂等性测试
make test-root         # Linux root 路径测试
```

### CI/CD

本地测试使用 Docker 容器验证安装脚本：

- ShellCheck 静态检查
- Docker 容器集成测试
- Kaku 检测逻辑验证
- 幂等性验证

详见 `docs/testing.md`。

## 注意事项

- 使用 Homebrew 统一管理软件包
- **不要提交敏感信息**（SSH 私钥、API token、密码等）
- 首次使用需修改 `.gitconfig` 中的用户名和邮箱
- `install.sh` 采用追加模式，不会覆盖现有 `~/.zshrc` 内容

## 致谢

- [Kaku](https://github.com/tw93/Kaku) - Zsh 配置部分参考了该项目
