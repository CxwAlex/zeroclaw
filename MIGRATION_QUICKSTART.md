# 🚀 ZeroClaw → MultiClaw 快速迁移指南

> **5 分钟启动迁移流程**

---

## 📋 迁移前准备

### 1. 检查环境

```bash
# 确认在 zeroclaw 根目录
pwd
# 应该输出：/Users/god/Documents/agent/zeroclaw

# 检查 Rust 版本
rustc --version
# 需要 1.87+

# 检查 Git 状态
git status
# 确保没有未提交的更改
```

### 2. 创建 GitHub 仓库

1. 访问 https://github.com/new
2. **Repository name**: `MultiClaw`
3. **Owner**: `CxwAlex`
4. **Visibility**: Public
5. ⚠️ **不要初始化**（不要添加 README/.gitignore/license）
6. 点击 "Create repository"

---

## 🏃 快速迁移（4 个步骤）

### 步骤 1: 复制核心代码

```bash
cd /Users/god/Documents/agent/zeroclaw

# 运行阶段 1 脚本
./migrate-to-multiclaw-step1.sh
```

**耗时**: ~2 分钟  
**输出**: `../multiclaw-workspace/multiclaw-target/`

---

### 步骤 2: 批量替换品牌

```bash
cd ../multiclaw-workspace/multiclaw-target

# 运行阶段 2 脚本
../../zeroclaw/migrate-to-multiclaw-step2.sh
```

**耗时**: ~1 分钟  
**操作**: 替换所有 `zeroclaw` → `multiclaw`

---

### 步骤 3: 推送到 GitHub

```bash
# 仍在 multiclaw-target 目录

# 运行阶段 3 脚本
../../zeroclaw/migrate-to-multiclaw-step3.sh
```

**耗时**: ~1 分钟（取决于网络）  
**输出**: 推送到 https://github.com/CxwAlex/MultiClaw

---

### 步骤 4: 原仓库标记清理

```bash
cd /Users/god/Documents/agent/zeroclaw

# 运行阶段 4 脚本
./migrate-to-multiclaw-step4.sh
```

**耗时**: ~30 秒  
**操作**: 添加迁移通知，标记可删除文件

---

## ✅ 验证迁移

### 验证新仓库

```bash
# 访问 GitHub
open https://github.com/CxwAlex/MultiClaw

# 检查：
# ✅ 文件结构完整
# ✅ README 显示正常
# ✅ CI/CD 工作流开始运行
```

### 验证构建

```bash
cd ../multiclaw-workspace/multiclaw-target

# 构建 Release 版本
cargo build --release

# 验证二进制
./target/release/multiclaw --version
./target/release/multiclaw --help

# 运行测试
cargo test --lib
```

---

## 📊 迁移统计

预期结果：

| 项目 | 数量 |
|------|------|
| Rust 源文件 | ~274 个 |
| 文档文件 | ~426 个 |
| 配置文件 | ~30 个 |
| 脚本文件 | ~70 个 |

---

## 🆘 常见问题

### Q1: 脚本没有执行权限

```bash
chmod +x migrate-to-multiclaw-*.sh
```

### Q2: 阶段 2 替换失败

确保在 `multiclaw-target` 目录运行：

```bash
pwd
# 应该包含：multiclaw-workspace/multiclaw-target
```

### Q3: Git 推送失败

检查 SSH key 或 HTTPS 凭证：

```bash
# 使用 HTTPS
git remote set-url origin https://github.com/CxwAlex/MultiClaw.git

# 或使用 SSH
git remote set-url origin git@github.com:CxwAlex/MultiClaw.git
```

### Q4: 构建失败

```bash
# 清理缓存
cargo clean

# 重新构建
cargo build --release

# 检查 Rust 版本
rustup update stable
rustc --version
```

---

## 📝 迁移后清理（可选）

### 删除标记文件

```bash
cd /Users/god/Documents/agent/zeroclaw

# 查看标记文件
ls -la .to-delete/

# 确认无误后删除
rm -rf .to-delete/
```

### 更新 GitHub 仓库描述

1. 访问 https://github.com/zeroclaw-labs/zeroclaw
2. 点击 "About" 区域的⚙️图标
3. 更新描述：
   ```
   ⚠️ Migrated to MultiClaw: https://github.com/CxwAlex/MultiClaw
   ```
4. 添加 Website: `https://github.com/CxwAlex/MultiClaw`

---

## 🎯 后续工作

### 短期（1-2 周）

- [ ] 完成基础迁移
- [ ] 验证所有现有功能
- [ ] 修复迁移问题

### 中期（2-4 周）

- [ ] 实现董事长 Agent
- [ ] 实现 A2A 通信协议
- [ ] 实现五层看板

### 长期（1-2 月）

- [ ] 完善多实例管理
- [ ] 实现分级记忆共享
- [ ] 优化性能

---

## 📞 获取帮助

1. **查看完整迁移方案**: `MIGRATION_PLAN.md`
2. **提交 Issue**: https://github.com/CxwAlex/MultiClaw/issues
3. **查看文档**: https://github.com/CxwAlex/MultiClaw/tree/main/docs

---

**最后更新**: 2026 年 3 月 1 日  
**迁移脚本版本**: v1.0
