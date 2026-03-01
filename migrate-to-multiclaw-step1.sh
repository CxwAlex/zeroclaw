#!/bin/bash
# MultiClaw 迁移脚本 - 阶段 1: 复制核心代码
# 用法：./migrate-to-multiclaw.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 检查是否在正确的目录
if [ ! -d "src" ] || [ ! -f "Cargo.toml" ]; then
    print_error "请在 zeroclaw 根目录运行此脚本"
    exit 1
fi

print_header "🚀 ZeroClaw → MultiClaw 迁移脚本 - 阶段 1: 复制"

# 创建工作目录
WORKSPACE_DIR="$(pwd)/../multiclaw-workspace"
SOURCE_DIR="$(pwd)"
TARGET_DIR="$WORKSPACE_DIR/multiclaw-target"

print_info "源目录：$SOURCE_DIR"
print_info "目标目录：$TARGET_DIR"

echo ""
read -p "继续迁移？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "迁移已取消"
    exit 0
fi

# 创建目标目录
print_header "步骤 1/6: 创建目标目录"
mkdir -p "$TARGET_DIR"
print_success "目标目录已创建"

# 复制核心源码
print_header "步骤 2/6: 复制核心源码"

echo "复制 src/ ..."
cp -r "$SOURCE_DIR/src" "$TARGET_DIR/src"

echo "复制 crates/ ..."
cp -r "$SOURCE_DIR/crates" "$TARGET_DIR/crates"

echo "复制 tests/ ..."
cp -r "$SOURCE_DIR/tests" "$TARGET_DIR/tests"

echo "复制 test_helpers/ ..."
cp -r "$SOURCE_DIR/test_helpers" "$TARGET_DIR/test_helpers"

echo "复制 benches/ ..."
cp -r "$SOURCE_DIR/benches" "$TARGET_DIR/benches"

echo "复制 examples/ ..."
cp -r "$SOURCE_DIR/examples" "$TARGET_DIR/examples"

print_success "核心源码复制完成"

# 复制配置文件
print_header "步骤 3/6: 复制配置文件"

cp "$SOURCE_DIR/Cargo.toml" "$TARGET_DIR/Cargo.toml"
cp "$SOURCE_DIR/Cargo.lock" "$TARGET_DIR/Cargo.lock"
cp "$SOURCE_DIR/rustfmt.toml" "$TARGET_DIR/rustfmt.toml"
cp "$SOURCE_DIR/clippy.toml" "$TARGET_DIR/clippy.toml"
cp "$SOURCE_DIR/.editorconfig" "$TARGET_DIR/.editorconfig"
cp "$SOURCE_DIR/.env.example" "$TARGET_DIR/.env.example"
cp "$SOURCE_DIR/.gitignore" "$TARGET_DIR/.gitignore"
cp "$SOURCE_DIR/.gitattributes" "$TARGET_DIR/.gitattributes"

print_success "配置文件复制完成"

# 复制 Docker 和部署配置
print_header "步骤 4/6: 复制 Docker 和部署配置"

cp "$SOURCE_DIR/Dockerfile" "$TARGET_DIR/Dockerfile"
cp "$SOURCE_DIR/.dockerignore" "$TARGET_DIR/.dockerignore"
cp "$SOURCE_DIR/docker-compose.yml" "$TARGET_DIR/docker-compose.yml"

print_success "Docker 配置复制完成"

# 复制文档和脚本
print_header "步骤 5/6: 复制文档和脚本"

echo "复制 docs/ ..."
cp -r "$SOURCE_DIR/docs" "$TARGET_DIR/docs"

echo "复制 scripts/ ..."
cp -r "$SOURCE_DIR/scripts" "$TARGET_DIR/scripts"

echo "复制 templates/ ..."
cp -r "$SOURCE_DIR/templates" "$TARGET_DIR/templates"

echo "复制 web/ ..."
cp -r "$SOURCE_DIR/web" "$TARGET_DIR/web"

echo "复制 site/ ..."
cp -r "$SOURCE_DIR/site" "$TARGET_DIR/site"

echo "复制 extensions/ ..."
cp -r "$SOURCE_DIR/extensions" "$TARGET_DIR/extensions"

echo "复制 firmware/ ..."
cp -r "$SOURCE_DIR/firmware" "$TARGET_DIR/firmware"

echo "复制 clients/ ..."
cp -r "$SOURCE_DIR/clients" "$TARGET_DIR/clients"

echo "复制 python/ ..."
cp -r "$SOURCE_DIR/python" "$TARGET_DIR/python"

echo "复制 multi_agent/ ..."
cp -r "$SOURCE_DIR/multi_agent" "$TARGET_DIR/multi_agent"

print_success "文档和脚本复制完成"

# 复制根目录文档和 GitHub 配置
print_header "步骤 6/6: 复制根目录文档和 GitHub 配置"

cp "$SOURCE_DIR/README.md" "$TARGET_DIR/README.md"
cp "$SOURCE_DIR/CHANGELOG.md" "$TARGET_DIR/CHANGELOG.md"
cp "$SOURCE_DIR/CONTRIBUTING.el.md" "$TARGET_DIR/CONTRIBUTING.el.md" 2>/dev/null || true
cp "$SOURCE_DIR/CODE_OF_CONDUCT.md" "$TARGET_DIR/CODE_OF_CONDUCT.md" 2>/dev/null || true

cp -r "$SOURCE_DIR/.github" "$TARGET_DIR/.github" 2>/dev/null || true

# 复制许可证
for license in LICENSE LICENSE-APACHE LICENSE-MIT NOTICE; do
    cp "$SOURCE_DIR/$license" "$TARGET_DIR/$license" 2>/dev/null || true
done

print_success "根目录文档复制完成"

# 统计信息
print_header "📊 迁移统计"

rust_files=$(find "$TARGET_DIR" -name "*.rs" | wc -l | tr -d ' ')
md_files=$(find "$TARGET_DIR" -name "*.md" | wc -l | tr -d ' ')
toml_files=$(find "$TARGET_DIR" -name "*.toml" | wc -l | tr -d ' ')
sh_files=$(find "$TARGET_DIR" -name "*.sh" | wc -l | tr -d ' ')

echo "Rust 源文件：$rust_files"
echo "文档文件：$md_files"
echo "配置文件：$toml_files"
echo "脚本文件：$sh_files"

print_success "✅ 阶段 1 完成！所有核心代码已复制到：$TARGET_DIR"

echo ""
print_info "下一步："
echo "1. 进入目标目录：cd $TARGET_DIR"
echo "2. 运行品牌替换脚本：../migrate-to-multiclaw-step2.sh"
echo ""
