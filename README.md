<p align="center">
  <img src="https://r2.unono.app/2026/05/823f369a1d565f9b9f2918c4e02837eb.png" alt="dev-setup" width="600" />
</p>

<h1 align="center">dev-setup</h1>

<p align="center">
  <strong>一行命令，任何机器复现你的极客终端</strong>
</p>

<p align="center">
  <a href="#快速开始"><img src="https://img.shields.io/badge/-快速开始-blue?style=flat-square" alt="快速开始" /></a>
  <img src="https://img.shields.io/badge/macOS-支持-success?style=flat-square&logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/Linux-支持-success?style=flat-square&logo=linux" alt="Linux" />
  <img src="https://img.shields.io/badge/Apple%20Silicon-支持-success?style=flat-square" alt="Apple Silicon" />
  <img src="https://img.shields.io/badge/root-支持-success?style=flat-square" alt="root" />
</p>

---

在一台全新的 macOS 或 Linux 机器上还原整套开发环境。跑一次搞定，跑两次也没副作用。

工具链交给 [mise](https://mise.jdx.dev) 管理，一份 `mise.toml` 覆盖所有平台。Linux 上不依赖 Homebrew，root 也能用。中国大陆网络自动切 USTC 镜像。

## 特性

- **跨平台** — macOS（含 Apple Silicon）和 Linux（Ubuntu / Debian / Fedora / Alpine / Arch）共用同一份配置
- **幂等** — 重复运行安全，不重复安装，不覆盖已有 `~/.zshrc` 内容
- **快** — CLI 工具走 GitHub release 预编译二进制（`aqua:` / `ubi:`），不需要本地编译
- **可离线验证** — Docker 容器化测试，`make test-all` 跑完全部路径
- **中国友好** — Homebrew 自动切 USTC 镜像，mise 配合 `https_proxy` 或 `GITHUB_TOKEN` 使用
- **[Kaku](https://kaku.app) 集成** — 检测到 Kaku 后自动让出插件管理，shell 启动快 80–120ms

## 快速开始

```bash
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

或者手动克隆：

```bash
git clone https://github.com/OiAnthony/dev-setup.git ~/.dev-setup
cd ~/.dev-setup && ./install.sh
```

装完开一个新终端窗口即可。

## 装了什么

### 通过 mise 管理（跨平台）

| 分类 | 工具 |
|------|------|
| Shell 体验 | starship, fzf, zoxide, fd, ripgrep, jq, neovim, yazi |
| Git 工具 | gh, lazygit, git-delta |
| 运行时 | Node.js (LTS), Go, Python 3.14, Java 21, uv |
| AI | Claude Code |

### 通过官方脚本安装

| 工具 | 说明 |
|------|------|
| Bun | JavaScript 运行时 & 包管理器 |
| pnpm | Node.js 包管理器 |
| Oh My Zsh | Zsh 框架 + 插件 |

### 平台差异

| | macOS | Linux |
|--|-------|-------|
| 基础依赖 | Homebrew（仅本体） | apt / dnf / apk / pacman |
| 字体 | Maple Mono NF CN, JetBrains Mono NF | — |
| root 支持 | 不支持（Homebrew 限制） | 支持 |

## 配置文件

`install.sh` 不覆盖 `~/.zshrc`，只在末尾追加一行 source。其他走软链接：

```
~/.gitconfig               → dotfiles/.gitconfig
~/.config/starship.toml    → dotfiles/starship.toml
~/.config/mise/config.toml → mise.toml
```

Shell 运行时配置在 `dotfiles/dev-setup.zsh`，包含 PATH、别名、mise activate、fzf、zoxide 等。如果检测到 [Kaku](https://kaku.app) 已安装，会跳过 Oh My Zsh 重复加载的插件，把这部分交给 Kaku，详见 [docs/zsh-optimization.md](docs/zsh-optimization.md)。

<details>
<summary><strong>内置别名</strong></summary>

| 别名 | 命令 | 条件 |
|------|------|------|
| `docker` | `podman` | 装了 podman |
| `code` | `code-insiders` | 装了 Insiders |
| `lg` | `lazygit` | 装了 lazygit |
| `cc` | `claude` | — |
| `cc-yolo` | `claude --dangerously-skip-permissions` | — |
| `oc` | `opencode` | — |
| `y` | yazi（退出时 cd） | — |
| `python` | `python3` | — |
| `pip` | `pip3` | — |

</details>

## 安装后

1. 改 Git 身份信息：

```bash
git config --global user.name "你的名字"
git config --global user.email "you@example.com"
```

2. （可选）中国大陆服务器配代理给 mise 用：

```bash
export https_proxy=http://127.0.0.1:7890
export GITHUB_TOKEN=ghp_xxx
```

## 自定义

加新工具，编辑 `mise.toml`，优先用 `aqua:` 或 `ubi:` backend：

```toml
"aqua:sharkdp/bat" = "latest"
```

然后：

```bash
mise install
```

改 shell 配置直接编辑 `dotfiles/dev-setup.zsh`，软链接已做好。

## 测试

测试跑在 Docker / Podman 容器里，验证安装脚本在干净环境的行为和幂等性。

```bash
make lint            # shellcheck
make test            # 普通用户集成测试
make test-kaku       # Kaku 分支
make test-idempotent # 幂等性（跑两次，diff 为空）
make test-root       # root 路径
make test-all        # 全部
```

详见 [docs/testing.md](docs/testing.md)。

## 项目结构

```
dev-setup/
├── install.sh                 # 安装入口
├── mise.toml                  # 工具清单（→ ~/.config/mise/config.toml）
├── Makefile                   # 测试入口
├── Dockerfile                 # 测试容器
├── dotfiles/
│   ├── dev-setup.zsh          # Shell 运行时配置（→ ~/.zshrc source）
│   ├── .gitconfig             # Git 配置（→ ~/.gitconfig）
│   └── starship.toml          # Prompt 主题（→ ~/.config/starship.toml）
├── scripts/
│   ├── test-install.sh        # 集成测试
│   ├── test-idempotent.sh     # 幂等性测试
│   └── test-piped-install.sh  # curl|bash 回归测试
└── docs/
    ├── zsh-optimization.md
    └── testing.md
```

## 致谢

- [mise](https://github.com/jdx/mise) — 工具链管理
- [Kaku](https://github.com/tw93/Kaku) — Zsh 配置参考
- [starship](https://github.com/starship/starship) — Shell prompt

## License

MIT
