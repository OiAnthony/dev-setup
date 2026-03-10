.PHONY: build lint test test-kaku test-idempotent test-all clean

IMAGE_NAME := dev-setup-test

# 构建 Docker 镜像
build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME) .

# ShellCheck 静态检查
lint:
	@echo "Running ShellCheck..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "Error: shellcheck not installed. Run: brew install shellcheck"; exit 1; }
	shellcheck install.sh
	@echo "Checking dev-setup.zsh (advisory only)..."
	shellcheck dotfiles/dev-setup.zsh || echo "Warning: zsh syntax may cause false positives"

# 集成测试
test: build
	@echo "Running integration test..."
	docker run --rm $(IMAGE_NAME) /home/testuser/dev-setup/scripts/test-install.sh

# Kaku 路径测试
test-kaku: build
	@echo "Running Kaku path test..."
	docker run --rm $(IMAGE_NAME) /home/testuser/dev-setup/scripts/test-install.sh --with-kaku

# 幂等性测试
test-idempotent: build
	@echo "Running idempotent test..."
	docker run --rm $(IMAGE_NAME) /home/testuser/dev-setup/scripts/test-idempotent.sh

# 运行所有测试
test-all: lint test test-kaku test-idempotent
	@echo "All tests passed!"

# 清理 Docker 镜像
clean:
	@echo "Removing Docker image..."
	docker rmi $(IMAGE_NAME) || true
