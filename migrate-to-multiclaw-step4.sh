#!/bin/bash
# MultiClaw 迁移脚本 - 阶段 4: 原仓库清理标记
# 用法：在 zeroclaw 根目录运行 ./migrate-to-multiclaw-step4.sh

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
    print_error "请在 zeroclaw 根目录运行此脚本"
    exit 1
fi

# 检查是否已完成迁移（检查目标仓库是否存在）
if [ ! -d "../multiclaw-workspace/multiclaw-target" ]; then
    print_error "未找到迁移目标目录！请先运行阶段 1-3 脚本"
    exit 1
fi

print_header "🧹 ZeroClaw → MultiClaw 迁移脚本 - 阶段 4: 原仓库清理标记"

echo ""
print_info "此脚本将："
echo "1. 创建迁移通知文件"
echo "2. 标记可删除的临时文件"
echo "3. 更新 README 添加迁移提示"
echo ""
echo "⚠️  不会删除任何文件，只是标记"
echo ""

read -p "继续清理标记？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "操作已取消"
    exit 0
fi

# 创建迁移通知文件
print_header "步骤 1/3: 创建迁移通知"

cat > MIGRATED_TO_MULTI_CLAW.md << 'EOF'
# ⚠️ ZeroClaw 已迁移至 MultiClaw

> **迁移日期**: 2026 年 3 月 1 日  
> **新仓库**: https://github.com/CxwAlex/MultiClaw  
> **状态**: 此仓库已归档，不再维护

---

## 🎉 迁移说明

ZeroClaw 项目已正式迁移至 **MultiClaw**，全新支持多 Agent 集群架构！

### ✨ MultiClaw 新特性

| 特性 | 说明 |
|------|------|
| 🌐 **全局董事长 Agent** | 用户分身，统一管理多实例 |
| 🏢 **多实例管理** | 分公司模式，支持≥10 个实例 |
| 🔗 **A2A 通信协议** | 标准化协议，跨团队/跨实例通信 |
| 📊 **五层可观测性** | 用户/董事长/CEO/团队/Agent 完整看板 |
| 🚀 **快速创建入口** | CLI/Telegram/Web 多端支持 |
| 🧠 **分级记忆共享** | 全局/集群/团队/工作四级知识共享 |

### 📦 迁移到新仓库

```bash
# 克隆新仓库
git clone https://github.com/CxwAlex/MultiClaw.git
cd MultiClaw

# 构建
cargo build --release

# 运行
./target/release/multiclaw --help
```

### 📋 原仓库状态

| 类别 | 状态 | 说明 |
|------|------|------|
| **核心代码** | ✅ 已迁移 | 所有功能已移至 MultiClaw |
| **设计文档** | 📦 保留参考 | multi_agent/ 目录保留作为历史参考 |
| **临时文件** | 🗑️ 已标记 | 待清理 |
| **后续更新** | 🆕 新仓库 | 请前往 MultiClaw |

### 🙏 致谢

感谢所有为 ZeroClaw 项目做出贡献的开发者、用户和社区成员！

MultiClaw 将在 ZeroClaw 的基础上继续发展，提供更强大的多 Agent 集群功能。

### 📞 联系方式

- **新仓库**: https://github.com/CxwAlex/MultiClaw
- **问题反馈**: https://github.com/CxwAlex/MultiClaw/issues
- **文档**: https://github.com/CxwAlex/MultiClaw/tree/main/docs

---

**最后更新**: 2026 年 3 月 1 日  
**归档状态**: 只读
EOF

print_success "迁移通知文件已创建"

# 标记可删除文件
print_header "步骤 2/3: 标记可删除文件"

# 创建删除标记目录
mkdir -p .to-delete

# 移动临时文件
if [ -f ".tmp_todo_probe" ]; then
    mv .tmp_todo_probe .to-delete/
    echo "标记：.tmp_todo_probe"
fi

# 创建删除清单
cat > .to-delete/DELETE_MANIFEST.md << 'EOF'
# 🗑️ 可删除文件清单

> **注意**: 这些文件已标记为删除，确认无误后执行删除操作

## 临时文件

- `.tmp_todo_probe` - 临时探针文件（无价值）

## 过程文档（可选）

以下文档是 MultiClaw 架构设计过程中的草稿，保留作为历史参考：

- `HYBRID_ARCHITECTURE_V4.md` - 混合架构 v4.0 设计草稿
- `HYBRID_ARCHITECTURE_V5.md` - 混合架构 v5.0 设计草稿
- `ENTERPRISE_OBSERVABLE_V5.md` - 企业可观测版 v5.0 设计草稿
- `ENTERPRISE_ORG_MULTI_AGENT_V3.md` - 企业组织模式 v3.0 设计草稿

## 删除操作

### 预览要删除的文件

```bash
ls -la .to-delete/
```

### 确认无误后删除

```bash
# 仅删除临时文件
rm -rf .to-delete/.tmp_todo_probe

# 或者删除所有标记文件（包括过程文档）
rm -rf .to-delete/
```

### 从 Git 历史中清理

```bash
# 如果需要从 Git 历史中彻底删除（谨慎使用）
git filter-branch --force --index-filter \
  "git rm -rf --cached --ignore-unmatch .to-delete" \
  --prune-empty --tag-name-filter cat -- --all
```

---

**标记日期**: 2026 年 3 月 1 日  
**状态**: 待确认删除
EOF

print_success "删除标记已创建"

# 更新 README 添加迁移提示
print_header "步骤 3/3: 更新 README"

# 在 README 开头添加迁移提示
if ! grep -q "已迁移至 MultiClaw" README.md; then
    cat > README_MIGRATION_NOTICE.md << 'EOF'
> ⚠️ **重要通知**: 本项目已迁移至 **MultiClaw**！
> 
> 🆕 新仓库：https://github.com/CxwAlex/MultiClaw
> 
> ✨ MultiClaw 支持多 Agent 集群架构，包含全局董事长 Agent、A2A 通信协议、五层可观测性等新特性。
> 
> 📦 请迁移到新仓库获取最新功能和更新。
> 
> ---

EOF

    # 合并到 README
    cat README_MIGRATION_NOTICE.md README.md > README.md.new
    mv README.md.new README.md
    rm -f README_MIGRATION_NOTICE.md

    print_success "README 已更新迁移提示"
else
    print_info "README 已包含迁移提示，跳过"
fi

# 提交更改
print_header "📝 提交更改"

git add MIGRATED_TO_MULTI_CLAW.md
git add .to-delete/
git add README.md

git commit -m "docs: 添加迁移通知至 MultiClaw

- 添加迁移说明文件
- 标记可删除的临时文件
- 更新 README 添加迁移提示
- 原仓库归档，后续更新请前往新仓库"

git push origin main 2>/dev/null || print_info "推送失败，请手动执行：git push"

print_success "提交完成"

# 总结
print_header "🎉 迁移标记完成！"

echo ""
echo "✅ 已完成："
echo "  - 迁移通知文件：MIGRATED_TO_MULTI_CLAW.md"
echo "  - 删除标记目录：.to-delete/"
echo "  - README 更新：添加迁移提示"
echo ""
print_info "后续步骤："
echo ""
echo "1. 验证新仓库：https://github.com/CxwAlex/MultiClaw"
echo ""
echo "2. 可选：删除标记的文件"
echo "   cd .to-delete/"
echo "   ls -la"
echo "   # 确认无误后删除"
echo ""
echo "3. 可选：更新 GitHub 仓库描述"
echo "   访问：https://github.com/zeroclaw-labs/zeroclaw"
echo "   更新 About 为：⚠️ Migrated to MultiClaw"
echo ""
echo "4. 通知社区成员迁移"
echo ""
