#!/bin/bash
# MultiClaw 迁移脚本 - 阶段 3: 推送至 GitHub
# 用法：./migrate-to-multiclaw-step3.sh

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

print_header "🚀 ZeroClaw → MultiClaw 迁移脚本 - 阶段 3: 推送到 GitHub"

# 检查 Cargo.toml 是否已更新
if grep -q 'name = "zeroclaw"' Cargo.toml; then
    print_error "Cargo.toml 还未更新！请先运行阶段 2 脚本"
    exit 1
fi

echo ""
print_info "在继续之前，请确保："
echo "1. 已在 GitHub 创建仓库：https://github.com/new"
echo "2. 仓库名：MultiClaw"
echo "3. 所有者：CxwAlex"
echo "4. ⚠️ 不要初始化仓库"
echo ""

read -p "是否已创建 GitHub 仓库？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "请先创建 GitHub 仓库，然后重新运行此脚本"
    exit 0
fi

# 初始化 Git
print_header "步骤 1/4: 初始化 Git 仓库"

if [ -d ".git" ]; then
    print_info "Git 仓库已存在，跳过初始化"
else
    git init
    git checkout -b main
    print_success "Git 仓库已初始化"
fi

# 添加所有文件
print_header "步骤 2/4: 添加文件"

git add -A
file_count=$(git status --porcelain | wc -l | tr -d ' ')
print_success "已添加 $file_count 个文件"

# 首次提交
print_header "步骤 3/4: 首次提交"

git commit -m "feat: initial MultiClaw release

- Migrated from ZeroClaw codebase
- Rebranded to MultiClaw
- Added multi-agent cluster architecture support
- Updated all configuration and documentation

Co-authored-by: ZeroClaw Team <zeroclaw-labs@users.noreply.github.com>"

print_success "首次提交完成"

# 关联远程仓库
print_header "步骤 4/4: 推送到 GitHub"

echo ""
print_info "请选择远程仓库 URL 类型："
echo "1. HTTPS (https://github.com/CxwAlex/MultiClaw.git)"
echo "2. SSH (git@github.com:CxwAlex/MultiClaw.git)"
echo ""
read -p "选择 (1/2): " -n 1 -r
echo

if [[ $REPLY =~ ^[1]$ ]]; then
    REMOTE_URL="https://github.com/CxwAlex/MultiClaw.git"
elif [[ $REPLY =~ ^[2]$ ]]; then
    REMOTE_URL="git@github.com:CxwAlex/MultiClaw.git"
else
    print_error "无效选择"
    exit 1
fi

# 检查是否已存在 origin
if git remote | grep -q "^origin$"; then
    print_info "更新现有 origin 远程"
    git remote set-url origin "$REMOTE_URL"
else
    print_info "添加 origin 远程"
    git remote add origin "$REMOTE_URL"
fi

print_info "远程仓库：$REMOTE_URL"
echo ""
read -p "确认推送？(y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "推送已取消"
    exit 0
fi

# 推送
git push -u origin main

print_success "推送到 GitHub 完成！"

# 验证
print_header "🎉 迁移完成！"

echo ""
echo "✅ 新仓库地址：https://github.com/CxwAlex/MultiClaw"
echo ""
print_info "后续步骤："
echo "1. 访问 GitHub 仓库验证文件"
echo "2. 检查 CI/CD 工作流是否正常运行"
echo "3. 运行本地测试确保功能正常"
echo "4. 返回原仓库运行阶段 4 脚本（清理）"
echo ""
