#!/bin/bash
# MultiClaw 迁移脚本 - 阶段 2: 批量替换品牌引用
# 用法：./migrate-to-multiclaw-step2.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    print_error "请在 multiclaw-target 目录运行此脚本"
    exit 1
fi

print_header "🔄 ZeroClaw → MultiClaw 迁移脚本 - 阶段 2: 品牌替换"

TARGET_DIR="$(pwd)"

echo ""
read -p "继续品牌替换？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "替换已取消"
    exit 0
fi

# 创建备份
print_header "步骤 1/7: 创建备份"

cp Cargo.toml Cargo.toml.bak
cp .env.example .env.example.bak

print_success "备份已创建"

# 替换 Cargo.toml
print_header "步骤 2/7: 替换 Cargo.toml"

sed -i '' 's/name = "zeroclaw"/name = "multiclaw"/g' Cargo.toml
sed -i '' 's/zeroclaw-labs/CxwAlex/g' Cargo.toml
sed -i '' 's/ZeroClaw/MultiClaw/g' Cargo.toml
sed -i '' 's/zero-claw/multi-claw/g' Cargo.toml

print_success "Cargo.toml 已更新"

# 替换 .env.example
print_header "步骤 3/7: 替换 .env.example"

sed -i '' 's/ZEROCLAW_/MULTICLAW_/g' .env.example
sed -i '' 's/ZeroClaw/MultiClaw/g' .env.example
sed -i '' 's/zeroclaw/multiclaw/g' .env.example

print_success ".env.example 已更新"

# 替换 Rust 源码中的常量
print_header "步骤 4/7: 替换 Rust 源码"

rust_count=0
find src crates -name '*.rs' -type f | while read file; do
    sed -i '' 's/zeroclaw/multiclaw/g' "$file"
    sed -i '' 's/ZeroClaw/MultiClaw/g' "$file"
    rust_count=$((rust_count + 1))
done

print_success "Rust 源码已更新"

# 替换文档
print_header "步骤 5/7: 替换文档"

md_count=0
find docs . -maxdepth 1 -name '*.md' -type f | while read file; do
    sed -i '' 's/ZeroClaw/MultiClaw/g' "$file"
    sed -i '' 's/zeroclaw/multiclaw/g' "$file"
    md_count=$((md_count + 1))
done

print_success "文档已更新"

# 替换脚本
print_header "步骤 6/7: 替换脚本"

find scripts -name '*.sh' -type f 2>/dev/null | while read file; do
    sed -i '' 's/ZEROCLAW_/MULTICLAW_/g' "$file"
    sed -i '' 's/zeroclaw/multiclaw/g' "$file"
    sed -i '' 's/ZeroClaw/MultiClaw/g' "$file"
done

print_success "脚本已更新"

# 重命名品牌相关文件
print_header "步骤 7/7: 重命名品牌相关文件"

# 根目录文件
if [ -f "zeroclaw_install.sh" ]; then
    mv zeroclaw_install.sh multiclaw_install.sh
    echo "重命名：zeroclaw_install.sh → multiclaw_install.sh"
fi

if [ -f "zeroclaw.png" ]; then
    mv zeroclaw.png multiclaw.png
    echo "重命名：zeroclaw.png → multiclaw.png"
fi

if [ -f "zero-claw.jpeg" ]; then
    mv zero-claw.jpeg multi-claw.jpeg
    echo "重命名：zero-claw.jpeg → multi-claw.jpeg"
fi

# 多 Agent 脚本
if [ -f "multi_agent/zeroclaw-instance.sh" ]; then
    mv multi_agent/zeroclaw-instance.sh multi_agent/multiclaw-instance.sh
    echo "重命名：zeroclaw-instance.sh → multiclaw-instance.sh"
fi

# 固件目录
for dir in firmware/zeroclaw-*; do
    if [ -d "$dir" ]; then
        new_dir=$(echo "$dir" | sed 's/zeroclaw/multiclaw/g')
        mv "$dir" "$new_dir"
        echo "重命名目录：$dir → $new_dir"
    fi
done

# Python 目录
if [ -d "python/zeroclaw_tools" ]; then
    mv python/zeroclaw_tools python/multiclaw_tools
    echo "重命名：python/zeroclaw_tools → python/multiclaw_tools"
fi

# 插件配置
find extensions -name '*.plugin.toml' | while read file; do
    new_file=$(echo "$file" | sed 's/zeroclaw/multiclaw/g')
    mv "$file" "$new_file"
    echo "重命名：$file → $new_file"
done

print_success "文件重命名完成"

# 验证替换结果
print_header "🔍 验证替换结果"

echo "检查剩余 zeroclaw 引用（前 20 条）:"
grep -r "zeroclaw" --include="*.toml" . 2>/dev/null | head -20 || echo "无 zeroclaw TOML 引用"

echo ""
echo "检查 multiclaw 引用（前 10 条）:"
grep -r "multiclaw" --include="*.toml" . 2>/dev/null | head -10 || echo "无 multiclaw 引用"

print_success "✅ 阶段 2 完成！品牌替换完成"

echo ""
print_info "下一步："
echo "1. 验证构建：cargo build --release"
echo "2. 运行测试：cargo test --lib"
echo "3. 如果一切正常，继续推送脚本"
