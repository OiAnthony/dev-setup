.PHONY: build lint test test-kaku test-idempotent test-piped test-root test-all clean

IMAGE_NAME := dev-setup-test

# 自动检测容器运行时（优先 docker，fallback 到 podman）
CONTAINER_RUNTIME := $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null)

# 项目在容器中的固定路径
PROJECT_PATH := /opt/dev-setup

# 构建镜像
build:
	@echo "Building container image with $(CONTAINER_RUNTIME)..."
	@test -n "$(CONTAINER_RUNTIME)" || { echo "Error: Neither docker nor podman found. Install one of them."; exit 1; }
	$(CONTAINER_RUNTIME) build -t $(IMAGE_NAME) .

# ShellCheck 静态检查
lint:
	@echo "Running ShellCheck..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "Error: shellcheck not installed. Run: brew install shellcheck"; exit 1; }
	shellcheck install.sh
	@echo "Checking dev-setup.zsh (advisory only)..."
	shellcheck dotfiles/dev-setup.zsh || echo "Warning: zsh syntax may cause false positives"

# 集成测试（普通用户路径）
test: build
	@echo "Running integration test (testuser)..."
	$(CONTAINER_RUNTIME) run --rm -u testuser $(IMAGE_NAME) $(PROJECT_PATH)/scripts/test-install.sh

# Kaku 路径测试（普通用户）
test-kaku: build
	@echo "Running Kaku path test..."
	$(CONTAINER_RUNTIME) run --rm -u testuser $(IMAGE_NAME) $(PROJECT_PATH)/scripts/test-install.sh --with-kaku

# 幂等性测试（普通用户）
test-idempotent: build
	@echo "Running idempotent test..."
	$(CONTAINER_RUNTIME) run --rm -u testuser $(IMAGE_NAME) $(PROJECT_PATH)/scripts/test-idempotent.sh

# curl | bash 场景回归测试（普通用户）
test-piped: build
	@echo "Running piped install regression test..."
	$(CONTAINER_RUNTIME) run --rm -u testuser $(IMAGE_NAME) $(PROJECT_PATH)/scripts/test-piped-install.sh

# Root 路径测试（关键：验证 mise 路径在 root 下也工作）
test-root: build
	@echo "Running integration test (root)..."
	$(CONTAINER_RUNTIME) run --rm -u 0 $(IMAGE_NAME) $(PROJECT_PATH)/scripts/test-install.sh

# 运行所有测试
test-all: lint test test-kaku test-idempotent test-piped test-root
	@echo "All tests passed!"

# 清理容器和镜像
clean:
	@echo "Removing containers using $(IMAGE_NAME)..."
	$(CONTAINER_RUNTIME) rm -f $$($(CONTAINER_RUNTIME) ps -aq --filter ancestor=$(IMAGE_NAME)) 2>/dev/null || true
	@echo "Removing container image..."
	$(CONTAINER_RUNTIME) rmi -f $(IMAGE_NAME) || true
