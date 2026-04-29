# 开发环境自动化配置

🥷 一份在新 macOS 或 Linux 机器上还原开发环境的脚本。一条命令把工具链、配置文件、Zsh 插件铺好，重复跑也不会出问题。

工具链统一交给 [mise](https://mise.jdx.dev) 管理，靠 `mise.toml` 一份清单同时覆盖 macOS 和 Linux（Ubuntu/Debian/Fedora/Alpine，包括 root）。Linux 上不依赖 Homebrew，绕开了它对 root 的限制。如果检测到机器在中国大陆，macOS 上的 Homebrew 本体会自动切到 USTC 镜像；mise 仍然走 GitHub release，必要时配 `https_proxy` 或 `GITHUB_TOKEN`。

## 快速开始

一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

或者克隆后再执行：

```bash
git clone https://github.com/OiAnthony/dev-setup.git
cd dev-setup
./install.sh
```

装完之后 `source ~/.zshrc` 生效，或者直接开一个新终端。

## 工具清单

跨平台的部分都在 [`mise.toml`](mise.toml) 里：

- CLI：starship、fzf、zoxide、fd、ripgrep、gh、lazygit、git-delta、neovim、btop、yazi、jq
- 运行时：Node.js（LTS）、Go、Python 3.14、uv、Java 21

后端优先 `aqua:` 和 `ubi:`，拉的是 GitHub release 的预编译二进制，不需要本地有编译工具链，root 也能装。

平台差异：

- macOS 会保留 Homebrew 本体（项目本身不再用 Brewfile，留给日常 `brew install` 兜底），并下载 Maple Mono NF CN 和 JetBrains Mono Nerd Font 到 `~/Library/Fonts/`
- Linux 用系统包管理器（apt/dnf/apk）装 git、curl、zsh、zip、build-essential 这类基础工具
- Bun、pnpm 在两端都通过官方脚本装，没有走 mise
- Oh My Zsh 和常用插件用 git clone 拉下来

## 配置文件

`install.sh` 不会覆盖 `~/.zshrc`，只在末尾追加一行 `source ".../dotfiles/dev-setup.zsh"`。其他配置走软链接：

| 软链接 | 指向 |
|--------|------|
| `~/.gitconfig` | `dotfiles/.gitconfig` |
| `~/.config/starship.toml` | `dotfiles/starship.toml` |
| `~/.config/mise/config.toml` | `mise.toml` |

`dev-setup.zsh` 是运行时入口，里面包含 PATH、别名、`mise activate`、Oh My Zsh、fzf、zoxide、yazi、pnpm、bun、Go 的环境配置。如果检测到 [Kaku.app](https://kaku.app) 已经装了，会跳过 Oh My Zsh 重复加载的插件，把这部分交给 Kaku，启动时间能省 80–120ms，详见 [docs/zsh-optimization.md](docs/zsh-optimization.md)。

内置别名：

| 别名 | 实际命令 | 备注 |
|------|---------|------|
| `docker` | `podman` | 装了 podman 才生效 |
| `code` | `code-insiders` | 装了 Insiders 才生效 |
| `python` | `python3` | |
| `pip` | `pip3` | |
| `cc` | `claude` | Claude Code CLI |
| `oc` | `opencode` | OpenCode CLI |
| `y` | yazi 函数 | 退出时 cd 到所在目录 |

## 首次使用

`.gitconfig` 里的用户名和邮箱是占位的，记得改：

```bash
vim ~/.gitconfig
```

然后 `source ~/.zshrc`。

## 维护

要加新工具，往 `mise.toml` 里加一行（优先 `aqua:` 或 `ubi:`），然后：

```bash
mise install
git commit -am "chore: add <tool>"
```

如果某个工具在 mise registry 里找不到：macOS 可以用 `brew install` 临时装一份，但不要进 repo；Linux 用对应发行版的包管理器或 cargo/pip。

改 shell 配置直接编辑 `dotfiles/dev-setup.zsh`，软链接已经做过，不需要再同步。

## 在 Linux 服务器（含 root）使用

直接以 root 跑：

```bash
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

中国大陆环境一般要先把代理或 token 设上，否则 mise 拉 GitHub release 会卡：

```bash
export https_proxy=http://127.0.0.1:7890
export GITHUB_TOKEN=ghp_xxx
curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash
```

`dev-setup.zsh` 会自动 `mise activate`，所以新 shell 里 mise 管的工具直接能用。也可以用 `mise exec -- <cmd>` 临时调一次。常用：

```bash
mise ls                    # 看已装版本
mise use --global node@22  # 切全局 Node 版本
mise install               # 按 mise.toml 装/更新
```

## 项目结构

```
dev-setup/
├── install.sh              # 安装入口（macOS → brew + mise + 字体；Linux → 系统包 + mise）
├── mise.toml               # 工具清单，软链接到 ~/.config/mise/config.toml
├── Makefile                # 测试入口
├── Dockerfile              # 测试用容器（Ubuntu 24.04，覆盖 testuser 和 root）
├── dotfiles/
│   ├── dev-setup.zsh      # 运行时配置，追加 source 到 ~/.zshrc
│   ├── .gitconfig
│   └── starship.toml
├── scripts/
│   ├── test-install.sh    # 集成测试
│   └── test-idempotent.sh # 幂等性测试
└── docs/
    ├── zsh-optimization.md
    └── testing.md
```

## 测试

测试跑在 Docker 容器里，验证安装脚本在干净环境下能不能工作，以及重复跑会不会出岔子。

```bash
brew install shellcheck   # 静态检查依赖

make lint                 # shellcheck install.sh + dev-setup.zsh
make test                 # 集成测试（普通用户路径）
make test-kaku            # 验证 Kaku 检测分支
make test-idempotent      # 重复跑两次，diff 应该为空
make test-root            # Linux root 路径
make test-all             # 上面全跑一遍
```

如果改了 `install.sh` 的行为，对应的 `scripts/test-install.sh` 或 `test-idempotent.sh` 一般也要一起改。详见 [docs/testing.md](docs/testing.md)。

## 注意事项

- 不要把 SSH 私钥、API token、密码这类东西提交进来
- `install.sh` 是追加模式，不会动 `~/.zshrc` 已有内容，但会保证 `dev-setup.zsh` 那一行只出现一次
- macOS 上 Homebrew 只是兜底，本项目不再依赖 Brewfile

## 致谢

- [Kaku](https://github.com/tw93/Kaku) - Zsh 配置部分参考了该项目
