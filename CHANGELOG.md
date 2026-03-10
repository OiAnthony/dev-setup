# 更新日志

## 2026-03-10

### 重大改进

- **模块化配置**：改用 `dev-setup.zsh` 通过 `source` 加载，不再覆盖 `~/.zshrc`
- **智能 Kaku 集成**：自动检测 Kaku 并跳过插件安装，避免重复加载
- **性能优化**：启动速度提升 80-120ms（详见 `docs/zsh-optimization.md`）
- **中国大陆镜像**：自动检测网络环境，中国大陆自动切换 USTC 镜像加速
- **自动化工具链**：Volta、Bun、pnpm、SDKMAN 由 `install.sh` 自动安装
- **Docker 测试**：新增隔离环境测试（集成测试、Kaku 路径测试、幂等性测试）

### 配置文件变更

- 删除 `dotfiles/.zshrc`（改为 `dev-setup.zsh`）
- 新增 `dotfiles/dev-setup.zsh`（统一环境配置）
- 更新 `install.sh`（追加模式 + Kaku 检测 + 中国镜像检测 + 自动安装工具链）
- 简化 `starship.toml`（移除 nodejs/lua 禁用配置）

### 测试基础设施

- 新增 `Makefile`（测试命令入口）
- 新增 `Dockerfile`（Ubuntu 24.04 + Homebrew 测试环境）
- 新增 `scripts/test-install.sh`（集成测试）
- 新增 `scripts/test-idempotent.sh`（幂等性测试）
- 新增 `.dockerignore`（优化 Docker 构建）

### 文档更新

- 更新 `README.md`（反映实际项目结构和新特性）
- 更新 `CLAUDE.md`（新增测试命令、中国镜像特性、完整配置流程）
- 新增 `docs/zsh-optimization.md`（性能优化说明）
- 新增 `docs/testing.md`（测试架构文档）
- 新增别名表格和特性列表

### 工具清单

- 新增 `uv`（Python 包管理器）
- 新增 `gitsu`（Git 用户切换）
- 新增 Nerd Fonts（Maple Mono CN、JetBrains Mono）
- 注释 `podman`（可选安装）
