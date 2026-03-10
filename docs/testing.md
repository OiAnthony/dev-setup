# 测试架构说明

## 概述

dev-setup 使用 Docker 容器提供隔离的测试环境，验证 `install.sh` 在干净系统上的安装结果。

## 测试类型

### 1. 静态检查（ShellCheck）

**目的**：在运行前捕获 Shell 脚本语法错误和常见问题

**覆盖文件**：
- `install.sh`
- `dotfiles/dev-setup.zsh`（advisory-only，zsh 语法可能误报）

**运行方式**：
```bash
make lint
```

### 2. 集成测试

**目的**：验证完整安装流程

**测试内容**：
- Homebrew 包安装（git, gh, node, python3, go, starship, fzf, fd, rg, jq, nvim, zoxide, tree）
- Oh My Zsh 安装
- Zsh 插件克隆（zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions）
- 软链接创建（.gitconfig, starship.toml）
- .zshrc 配置追加
- 可选工具安装（Bun, pnpm, SDKMAN）

**运行方式**：
```bash
make test
```

### 3. Kaku 路径测试

**目的**：验证 Kaku 检测逻辑

**测试场景**：
- 创建 `~/.config/kaku/zsh/kaku.zsh` 模拟 Kaku 存在
- 运行 install.sh
- 验证插件安装被正确跳过（避免重复）

**运行方式**：
```bash
make test-kaku
```

### 4. 幂等性测试

**目的**：验证重复运行安全性

**测试内容**：
- 运行 install.sh 两次
- 验证软链接未改变（md5sum）
- 验证 .zshrc 中 source 行只出现一次（未重复追加）

**运行方式**：
```bash
make test-idempotent
```

## Docker 架构

### 基础镜像

**FROM**: ubuntu:24.04

**预装组件**：
- 系统依赖：build-essential, curl, git, zsh, sudo
- Homebrew（独立层，优化缓存）
- 非 root 用户 testuser（Homebrew 要求）

### 缓存优化

**分层策略**：
1. 系统依赖安装（很少变化）
2. Homebrew 安装（很少变化）
3. 项目文件复制（频繁变化）

**效果**：
- 冷缓存：~10 分钟
- 热缓存：~4 分钟（仅重新复制项目文件）

## CI/CD 流程

### GitHub Actions

**触发条件**：
- push 到 main 分支
- 创建 PR

**Job 1: lint**（快速门禁）
- 安装 ShellCheck
- 检查 install.sh
- 检查 dev-setup.zsh（advisory-only）

**Job 2: integration**（依赖 lint）
- 构建 Docker 镜像（使用 GitHub Actions 缓存）
- 运行集成测试
- 运行 Kaku 路径测试
- 运行幂等性测试

## 不覆盖的范围

### macOS 特定路径

Docker 无法运行 macOS，以下路径不会被测试：
- Apple Silicon Homebrew 路径：`/opt/homebrew`
- Intel Mac Homebrew 路径：`/usr/local`

**缓解措施**：开发者在本地 macOS 环境手动测试

### Shell 启动性能

不自动化测试 `time zsh -i -c exit`，原因：
- 容器环境性能不代表真实环境
- 性能优化主要针对 Kaku 集成，需手动验证

### 交互式 Shell 会话

不测试完整的 shell 会话，仅验证：
- 配置文件存在
- 配置文件被正确引用
- 软链接指向正确

## 本地调试

### 进入容器

```bash
# 构建镜像
make build

# 进入容器
docker run -it dev-setup-test bash

# 手动运行安装
./install.sh

# 检查结果
command -v git
ls -la ~/.gitconfig
cat ~/.zshrc
```

### 查看测试日志

测试脚本使用颜色输出：
- 🟢 绿色：成功
- 🔴 红色：失败
- 🟡 黄色：警告（可选工具未安装）

## 维护指南

### 添加新工具验证

编辑 `scripts/test-install.sh`：

```bash
# 在 "验证 Homebrew 包" 部分添加
for cmd in git gh node python3 go starship fzf fd rg jq nvim zoxide tree NEW_TOOL; do
    check_command "$cmd" || ((failed++))
done
```

### 修改 Kaku 检测逻辑

同时更新：
1. `install.sh` - 安装时检测
2. `dotfiles/dev-setup.zsh` - 运行时检测
3. `scripts/test-install.sh` - 测试验证

### 更新 CI 缓存

GitHub Actions 缓存键基于 Dockerfile 内容，修改 Dockerfile 会自动失效缓存。

## 故障排查

### 测试失败：Homebrew 包未安装

**原因**：Brewfile 中的包在 Linux 上不可用

**解决**：
- 检查包是否支持 Linux
- 使用 `brew info <package>` 验证
- 考虑添加平台检测逻辑

### 测试失败：软链接验证

**原因**：路径不匹配

**解决**：
- 检查 `install.sh` 中的软链接创建逻辑
- 验证 `PROJECT_ROOT` 变量正确

### CI 超时

**原因**：Homebrew 安装耗时过长

**解决**：
- 检查 GitHub Actions 缓存是否生效
- 考虑减少 Brewfile 中的包数量（仅测试代表性工具）

## 参考

- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Caching](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
