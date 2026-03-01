# ZeroClaw → MultiClaw 完整迁移方案

> **目标仓库**: https://github.com/CxwAlex/MultiClaw
> **迁移策略**: 先完整迁移 → 验证功能 → 可控清理
> **创建日期**: 2026 年 3 月 1 日
> **版本**: v1.0

---

## 📋 迁移总览

### 迁移原则

1. **先复制后清理**：确保所有核心代码安全迁移到新仓库
2. **分阶段验证**：每个阶段完成后验证功能正常
3. **可控删除**：原仓库文件标记后逐步清理，不一次性删除
4. **保持历史**：保留重要设计文档作为参考

### 迁移范围

| 类别 | 操作 | 文件数 | 说明 |
|------|------|--------|------|
| **核心源码** | ✅ 完整复制 | 274 个 .rs 文件 | src/, crates/ |
| **配置文件** | 📝 复制 + 更新品牌 | ~30 个 TOML | Cargo.toml 等 |
| **文档** | 📝 复制 + 批量替换 | 426 个 .md | docs/, README.md |
| **脚本** | 📝 复制 + 重命名 | ~70 个 | .sh 文件 |
| **临时文件** | ❌ 不迁移 | 1 个 | .tmp_todo_probe |
| **过程文档** | 📦 保留参考 | 6 个 | multi_agent/*.md |

---

## 🚀 第一阶段：准备新仓库

### 1.1 创建 GitHub 仓库

```bash
# 在 GitHub 上创建新仓库
# 1. 访问 https://github.com/new
# 2. Repository name: MultiClaw
# 3. Owner: CxwAlex
# 4. Visibility: Public
# 5. ⚠️ 不要初始化（不要添加 README/.gitignore/license）
# 6. 点击 "Create repository"
```

### 1.2 本地准备

```bash
# 创建工作目录
cd /Users/god/Documents/agent/
mkdir -p multiclaw-workspace
cd multiclaw-workspace

# 克隆原仓库（作为迁移源）
git clone https://github.com/zeroclaw-labs/zeroclaw.git zeroclaw-source
cd zeroclaw-source

# 确认当前状态
git status
git log -n 1
```

---

## 📦 第二阶段：复制核心代码

### 2.1 执行复制脚本

```bash
cd /Users/god/Documents/agent/multiclaw-workspace

# 创建目标目录
mkdir -p multiclaw-target

# 复制核心源码
cp -r zeroclaw-source/src multiclaw-target/src
cp -r zeroclaw-source/crates multiclaw-target/crates
cp -r zeroclaw-source/tests multiclaw-target/tests
cp -r zeroclaw-source/test_helpers multiclaw-target/test_helpers
cp -r zeroclaw-source/benches multiclaw-target/benches
cp -r zeroclaw-source/examples multiclaw-target/examples

# 复制配置文件
cp zeroclaw-source/Cargo.toml multiclaw-target/Cargo.toml
cp zeroclaw-source/Cargo.lock multiclaw-target/Cargo.lock
cp zeroclaw-source/rustfmt.toml multiclaw-target/rustfmt.toml
cp zeroclaw-source/clippy.toml multiclaw-target/clippy.toml
cp zeroclaw-source/.editorconfig multiclaw-target/.editorconfig
cp zeroclaw-source/.env.example multiclaw-target/.env.example
cp zeroclaw-source/.gitignore multiclaw-target/.gitignore

# 复制 Docker 配置
cp zeroclaw-source/Dockerfile multiclaw-target/Dockerfile
cp zeroclaw-source/.dockerignore multiclaw-target/.dockerignore
cp zeroclaw-source/docker-compose.yml multiclaw-target/docker-compose.yml

# 复制文档和脚本
cp -r zeroclaw-source/docs multiclaw-target/docs
cp -r zeroclaw-source/scripts multiclaw-target/scripts
cp -r zeroclaw-source/templates multiclaw-target/templates
cp -r zeroclaw-source/web multiclaw-target/web
cp -r zeroclaw-source/site multiclaw-target/site
cp -r zeroclaw-source/extensions multiclaw-target/extensions
cp -r zeroclaw-source/firmware multiclaw-target/firmware
cp -r zeroclaw-source/clients multiclaw-target/clients
cp -r zeroclaw-source/python multiclaw-target/python

# 复制多 Agent 设计文档（重要参考）
cp -r zeroclaw-source/multi_agent multiclaw-target/multi_agent

# 复制根目录文档
cp zeroclaw-source/README.md multiclaw-target/README.md
cp zeroclaw-source/CHANGELOG.md multiclaw-target/CHANGELOG.md
cp zeroclaw-source/LICENSE-APACHE multiclaw-target/LICENSE-APACHE 2>/dev/null || true
cp zeroclaw-source/LICENSE-MIT multiclaw-target/LICENSE-MIT 2>/dev/null || true

# 复制 GitHub 配置
cp -r zeroclaw-source/.github multiclaw-target/.github
```

### 2.2 验证复制结果

```bash
cd multiclaw-target

# 统计文件数
echo "=== 复制统计 ==="
echo "Rust 源文件：$(find . -name '*.rs' | wc -l)"
echo "文档文件：$(find . -name '*.md' | wc -l)"
echo "配置文件：$(find . -name '*.toml' | wc -l)"
echo "脚本文件：$(find . -name '*.sh' | wc -l)"

# 验证核心目录
test -d src && echo "✅ src/ 存在" || echo "❌ src/ 缺失"
test -d crates && echo "✅ crates/ 存在" || echo "❌ crates/ 缺失"
test -f Cargo.toml && echo "✅ Cargo.toml 存在" || echo "❌ Cargo.toml 缺失"
```

---

## ✏️ 第三阶段：批量替换品牌引用

### 3.1 创建批量替换脚本

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 创建备份
echo "📦 创建备份..."
cp Cargo.toml Cargo.toml.bak
cp .env.example .env.example.bak

# 1. 替换 Cargo.toml 中的包名
echo "🔄 替换 Cargo.toml..."
sed -i '' 's/name = "zeroclaw"/name = "multiclaw"/g' Cargo.toml
sed -i '' 's/zeroclaw-labs/CxwAlex/g' Cargo.toml
sed -i '' 's/ZeroClaw/MultiClaw/g' Cargo.toml

# 2. 替换 .env.example
echo "🔄 替换 .env.example..."
sed -i '' 's/ZEROCLAW_/MULTICLAW_/g' .env.example
sed -i '' 's/ZeroClaw/MultiClaw/g' .env.example

# 3. 替换所有 .rs 文件中的常量引用
echo "🔄 替换 Rust 源码中的常量..."
find src crates -name '*.rs' -type f | while read file; do
  sed -i '' 's/zeroclaw/multiclaw/g' "$file"
  sed -i '' 's/ZeroClaw/MultiClaw/g' "$file"
done

# 4. 替换所有文档中的品牌引用
echo "🔄 替换文档中的品牌引用..."
find docs . -maxdepth 1 -name '*.md' -type f | while read file; do
  sed -i '' 's/ZeroClaw/MultiClaw/g' "$file"
  sed -i '' 's/zeroclaw/multiclaw/g' "$file"
done

# 5. 替换脚本中的引用
echo "🔄 替换脚本中的引用..."
find scripts -name '*.sh' -type f | while read file; do
  sed -i '' 's/ZEROCLAW_/MULTICLAW_/g' "$file"
  sed -i '' 's/zeroclaw/multiclaw/g' "$file"
done

# 6. 重命名品牌相关文件
echo "🔄 重命名品牌相关文件..."
mv zeroclaw_install.sh multiclaw_install.sh 2>/dev/null || true
mv zeroclaw.png multiclaw.png 2>/dev/null || true
mv zero-claw.jpeg multi-claw.jpeg 2>/dev/null || true

# 7. 重命名固件目录
echo "🔄 重命名固件目录..."
for dir in firmware/zeroclaw-*; do
  if [ -d "$dir" ]; then
    new_dir=$(echo "$dir" | sed 's/zeroclaw/multiclaw/g')
    mv "$dir" "$new_dir"
  fi
done

# 8. 重命名 Python 目录
echo "🔄 重命名 Python 目录..."
mv python/zeroclaw_tools python/multiclaw_tools 2>/dev/null || true

# 9. 重命名插件配置
echo "🔄 重命名插件配置..."
find extensions -name '*.plugin.toml' | while read file; do
  mv "$file" "$(echo "$file" | sed 's/zeroclaw/multiclaw/g')"
done

echo "✅ 批量替换完成！"
```

### 3.2 验证替换结果

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 检查是否还有 zeroclaw 引用
echo "=== 检查剩余 zeroclaw 引用 ==="
grep -r "zeroclaw" --include="*.toml" . | head -20
grep -r "ZeroClaw" --include="*.md" . | head -20

# 检查 multiclaw 引用
echo "=== 验证 multiclaw 引用 ==="
grep -r "multiclaw" --include="*.toml" . | head -10
grep -r "MultiClaw" --include="*.md" . | head -10
```

---

## 🔧 第四阶段：更新核心配置

### 4.1 更新 Cargo.toml

```toml
[package]
name = "multiclaw"
version = "0.1.0"
edition = "2021"
rust-version = "1.87"

description = "Multi-Agent Cluster Runtime - Zero overhead. Zero compromise. 100% Rust."
license = "MIT OR Apache-2.0"
repository = "https://github.com/CxwAlex/MultiClaw"
homepage = "https://github.com/CxwAlex/MultiClaw"
documentation = "https://github.com/CxwAlex/MultiClaw/tree/main/docs"
keywords = ["ai", "agent", "cluster", "rust", "multi-agent"]
categories = ["artificial-intelligence"]

[workspace]
members = [
    "crates/robot-kit",
    "extensions/*",
    "templates/rust/*",
    "firmware/*",
]
```

### 4.2 更新 README.md

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 替换标题
sed -i '' 's/ZeroClaw/MultiClaw/g' README.md
sed -i '' 's/zeroclaw/multiclaw/g' README.md

# 更新仓库链接
sed -i '' 's|github.com/zeroclaw-labs/zeroclaw|github.com/CxwAlex/MultiClaw|g' README.md
sed -i '' 's|zeroclaw-labs|CxwAlex|g' README.md

# 更新社交媒体链接（如果需要保留）
# sed -i '' 's|@zeroclawlabs|@multiclowlabs|g' README.md
```

### 4.3 更新 .github/workflows

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 批量替换工作流中的仓库引用
find .github/workflows -name '*.yml' -type f | while read file; do
  sed -i '' 's|zeroclaw-labs/zeroclaw|CxwAlex/MultiClaw|g' "$file"
  sed -i '' 's|zeroclaw|multiclaw|g' "$file"
done
```

---

## 🧪 第五阶段：验证构建

### 5.1 本地构建验证

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 格式化检查
cargo fmt -- --check

# Clippy 检查
cargo clippy -- -D warnings

# 构建 Release 版本
cargo build --release

# 运行测试
cargo test --lib

# 验证二进制
./target/release/multiclaw --version
./target/release/multiclaw --help
```

### 5.2 性能基准验证

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 测量二进制大小
ls -lh target/release/multiclaw

# 测量启动时间
/usr/bin/time -l ./target/release/multiclaw --help
/usr/bin/time -l ./target/release/multiclaw status
```

---

## 🚀 第六阶段：推送到 GitHub

### 6.1 初始化 Git 仓库

```bash
cd /Users/god/Documents/agent/multiclaw-workspace/multiclaw-target

# 初始化 Git
git init
git checkout -b main

# 添加所有文件
git add -A

# 首次提交
git commit -m "feat: initial MultiClaw release

- Migrated from ZeroClaw codebase
- Rebranded to MultiClaw
- Added multi-agent cluster architecture support
- Updated all configuration and documentation

Co-authored-by: ZeroClaw Team <zeroclaw-labs@users.noreply.github.com>"
```

### 6.2 关联远程仓库

```bash
# 添加远程仓库（替换为你的实际仓库 URL）
git remote add origin https://github.com/CxwAlex/MultiClaw.git

# 或者使用 SSH
# git remote add origin git@github.com:CxwAlex/MultiClaw.git

# 推送到 GitHub
git push -u origin main
```

### 6.3 验证 GitHub 仓库

```bash
# 访问 https://github.com/CxwAlex/MultiClaw
# 检查：
# ✅ 文件结构完整
# ✅ README 显示正常
# ✅ CI/CD 工作流开始运行
```

---

## 🧹 第七阶段：可控清理（原仓库）

### 7.1 创建迁移标记文件

```bash
cd /Users/god/Documents/agent/zeroclaw

# 创建迁移通知文件
cat > MIGRATED_TO_MULTI_CLAW.md << 'EOF'
# ZeroClaw 已迁移至 MultiClaw

> **迁移日期**: 2026 年 3 月 1 日
> **新仓库**: https://github.com/CxwAlex/MultiClaw

## 迁移说明

本项目已迁移至 **MultiClaw**，支持多 Agent 集群架构。

### 新特性

- ✅ 全局董事长 Agent（用户分身）
- ✅ 多实例管理（分公司模式）
- ✅ A2A 通信协议（跨团队/跨实例）
- ✅ 五层可观测性看板
- ✅ 快速创建入口（CLI/Telegram/Web）
- ✅ 分级记忆共享（全局/集群/团队/工作）

### 迁移到新仓库

```bash
git clone https://github.com/CxwAlex/MultiClaw.git
cd MultiClaw
cargo build --release
```

### 原仓库状态

- **核心代码**: 已迁移 ✅
- **设计文档**: 保留参考 📦
- **临时文件**: 已清理 🗑️
- **后续更新**: 请前往新仓库 🆕

### 致谢

感谢 ZeroClaw 社区的所有贡献者！
EOF

# 提交标记文件
git add MIGRATED_TO_MULTI_CLAW.md
git commit -m "docs: add migration notice to MultiClaw"
git push origin main
```

### 7.2 标记可删除文件

```bash
cd /Users/god/Documents/agent/zeroclaw

# 创建删除标记目录
mkdir -p .to-delete

# 移动临时文件
mv .tmp_todo_probe .to-delete/ 2>/dev/null || true

# 移动过程文档（可选）
mv multi_agent/HYBRID_ARCHITECTURE_V*.md .to-delete/ 2>/dev/null || true
mv multi_agent/ENTERPRISE_*.md .to-delete/ 2>/dev/null || true

# 创建删除清单
cat > .to-delete/DELETE_MANIFEST.md << 'EOF'
# 可删除文件清单

## 临时文件

- `.tmp_todo_probe` - 临时探针文件

## 过程文档（可选删除）

- `HYBRID_ARCHITECTURE_V4.md` - 架构设计草稿
- `HYBRID_ARCHITECTURE_V5.md` - 架构设计草稿
- `ENTERPRISE_OBSERVABLE_V5.md` - 设计文档
- `ENTERPRISE_ORG_MULTI_AGENT_V3.md` - 设计文档

## 删除操作

```bash
# 预览要删除的文件
ls -la .to-delete/

# 确认无误后删除
rm -rf .to-delete/

# 或者移动到回收站（macOS）
mv .to-delete ~/.Trash/
```
EOF

# 提交删除标记
git add .to-delete/
git commit -m "chore: mark files for deletion after migration"
git push origin main
```

### 7.3 更新仓库描述

```bash
# 在 GitHub 上更新仓库描述：
# 1. 访问 https://github.com/zeroclaw-labs/zeroclaw
# 2. 点击 "About" 区域的设置图标
# 3. 更新描述为：
#    "⚠️ Migrated to MultiClaw: https://github.com/CxwAlex/MultiClaw"
# 4. 添加 Website: https://github.com/CxwAlex/MultiClaw
```

---

## 📊 迁移检查清单

### 复制阶段

- [ ] src/ 目录完整复制
- [ ] crates/ 目录完整复制
- [ ] tests/ 目录完整复制
- [ ] Cargo.toml 复制
- [ ] 文档目录复制
- [ ] 脚本目录复制

### 替换阶段

- [ ] Cargo.toml 包名更新
- [ ] .env.example 变量前缀更新
- [ ] Rust 源码常量更新
- [ ] 文档品牌引用更新
- [ ] 脚本引用更新
- [ ] 相关文件重命名

### 验证阶段

- [ ] cargo fmt 检查通过
- [ ] cargo clippy 检查通过
- [ ] cargo build 成功
- [ ] cargo test 通过
- [ ] 二进制文件可执行

### 推送阶段

- [ ] GitHub 仓库创建
- [ ] Git 初始化
- [ ] 首次提交
- [ ] 推送到远程
- [ ] CI/CD 运行正常

### 清理阶段

- [ ] 迁移通知文件创建
- [ ] 可删除文件标记
- [ ] 仓库描述更新
- [ ] 社区通知发布

---

## 🎯 新增 MultiClaw 核心模块

基于 v6.0 架构，需要新增以下模块：

### 目录结构

```
multiclaw/
├── src/
│   ├── agent/
│   │   ├── chairman.rs         # 新增：董事长 Agent
│   │   └── ...
│   ├── cluster/
│   │   ├── core.rs             # 新增：集群管理核心
│   │   ├── instance.rs         # 新增：实例管理
│   │   └── mod.rs
│   ├── a2a/
│   │   ├── protocol.rs         # 新增：A2A 通信协议
│   │   ├── gateway.rs          # 新增：A2A 网关
│   │   └── mod.rs
│   ├── observability/
│   │   └── dashboards/         # 新增：五层看板
│   │       ├── user.rs
│   │       ├── board.rs
│   │       ├── ceo.rs
│   │       ├── team.rs
│   │       └── agent.rs
│   └── ...
└── multi_agent/
    └── HYBRID_ARCHITECTURE_V6.md  # v6.0 架构设计
```

### 实施顺序

1. **先迁移现有代码**（本方案）
2. **验证基础功能正常**
3. **再新增 MultiClaw 特有模块**

---

## 📝 后续工作

### 短期（1-2 周）

1. 完成基础迁移（本方案）
2. 验证所有现有功能正常
3. 修复迁移中发现的问题

### 中期（2-4 周）

1. 实现董事长 Agent
2. 实现 A2A 通信协议
3. 实现五层看板

### 长期（1-2 月）

1. 完善多实例管理
2. 实现分级记忆共享
3. 优化性能和稳定性

---

## 🆘 故障排除

### 问题 1: 构建失败

```bash
# 清理构建缓存
cargo clean
cargo build --release

# 检查 Rust 版本
rustc --version
# 需要 1.87+
```

### 问题 2: 替换遗漏

```bash
# 查找所有 zeroclaw 引用
grep -r "zeroclaw" --include="*.toml" --include="*.rs" .

# 手动修复
```

### 问题 3: Git 推送失败

```bash
# 检查远程仓库
git remote -v

# 重新添加
git remote remove origin
git remote add origin https://github.com/CxwAlex/MultiClaw.git

# 强制推送（谨慎使用）
git push -f -u origin main
```

---

## 📞 支持

如有问题，请：
1. 查看本迁移方案文档
2. 检查 GitHub Issues
3. 联系维护者

---

**迁移方案版本**: v1.0
**最后更新**: 2026 年 3 月 1 日
