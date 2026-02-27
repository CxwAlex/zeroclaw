# ZeroClaw 项目上下文

## 项目概述

ZeroCllaw 是一个**零开销、零妥协、100% Rust** 的 AI 代理运行时系统。专为高性能、高效率、高稳定性设计，可在低成本硬件上运行（<5MB 内存，$10 硬件）。

### 核心特性

- **精简运行时**：Release 构建仅需几 MB 内存
- **快速冷启动**：命令启动接近瞬时（<10ms）
- **可移植架构**：支持 ARM、x86、RISC-V 的单二进制工作流
- **完全可插拔**：基于 Trait 的架构，支持 Provider/Channel/Tool/Memory 等组件热插拔

### 技术栈

- **语言**：Rust 1.87+
- **异步运行时**：Tokio（精简特性配置）
- **HTTP 客户端**：reqwest（rustls 后端）
- **配置**：TOML
- **持久化**：SQLite（bundled）、PostgreSQL（可选）
- **Web 框架**：axum（gateway）

## 项目结构

```
zeroclaw/
├── src/                      # 主源码
│   ├── agent/                # 代理编排循环
│   ├── channels/             # 通信渠道（Telegram/Discord/Slack 等）
│   ├── providers/            # AI 模型提供商（OpenAI/Anthropic 等）
│   ├── tools/                # 工具执行（shell/file/memory 等）
│   ├── memory/               # 记忆系统（SQLite/Markdown 后端）
│   ├── security/             # 安全策略、配对、密钥存储
│   ├── gateway/              # Webhook 网关服务器
│   ├── runtime/              # 运行时适配器
│   ├── peripherals/          # 硬件外设（STM32/RPi GPIO）
│   ├── config/               # 配置 schema 和加载
│   └── main.rs               # CLI 入口点
├── crates/
│   └── robot-kit/            # 机器人套件
├── docs/                     # 文档中心
├── scripts/                  # 构建/安装脚本
├── tests/                    # 集成测试
└── Cargo.toml                # 项目配置
```

## 构建与运行

### 前置条件

**macOS / Linux:**
```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装构建工具
# macOS: xcode-select --install
# Linux (Debian/Ubuntu): sudo apt install build-essential pkg-config
```

**Windows:**
```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
winget install Rustlang.Rustup
```

### 快速开始

```bash
# 克隆仓库
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw

# 一键安装（推荐）
./bootstrap.sh

# 或者手动构建
cargo build --release

# 运行测试
cargo test --locked

# 格式化 & Lint
cargo fmt && cargo clippy

# 快速测试脚本
./quick_test.sh
```

### 常用命令

```bash
# 初始化配置
zeroclaw onboard --api-key sk-... --provider openrouter

# 运行代理
zeroclaw agent -m "Hello, ZeroClaw!"

# 交互模式
zeroclaw agent

# 启动网关
zeroclaw gateway

# 后台服务
zeroclaw daemon
zeroclaw service install
zeroclaw service status

# 状态检查
zeroclaw status
zeroclaw doctor

# 生成 Shell 补全
source <(zeroclaw completions bash)
```

### 开发模式

```bash
# 调试构建
cargo build

# 快速 Release 构建（适合高性能机器）
cargo build --profile release-fast

# 运行特定测试
cargo test telegram --lib

# 严格 Lint
./scripts/ci/rust_quality_gate.sh --strict
```

## 开发规范

### 代码风格

- **命名**：
  - 模块/文件：`snake_case`
  - 类型/Trait/枚举：`PascalCase`
  - 函数/变量：`snake_case`
  - 常量/Static：`SCREAMING_SNAKE_CASE`

- **架构原则**：
  - 通过实现 Trait + 工厂注册扩展功能
  - 避免跨子系统耦合
  - 保持模块单一职责
  - 失败要快速且明确

### 提交规范

使用 Conventional Commits：

```
<type>(<scope>): <description>

[optional body]

Closes #<issue>
```

**Type 类型**：
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `test`: 测试相关
- `refactor`: 重构
- `chore`: 构建/工具/配置

### PR 工作流

1. Fork 仓库并创建功能分支
2. 启用 Git hooks：`git config core.hooksPath .githooks`
3. 提交前运行：`cargo fmt && cargo clippy && cargo test`
4. 向 `dev` 分支提交 PR
5. 等待 CI 检查和 Review

### 测试要求

```bash
# 完整测试套件
./test_telegram_integration.sh

# 快速冒烟测试
./quick_test.sh

# 特定模块测试
cargo test <module> --lib
```

## 核心架构

### Trait 驱动设计

| 子系统 | Trait | 内置实现 |
|--------|-------|----------|
| AI 模型 | `Provider` | OpenRouter, Anthropic, OpenAI, Gemini 等 |
| 通信渠道 | `Channel` | CLI, Telegram, Discord, Slack, Matrix 等 |
| 工具 | `Tool` | shell, file, memory, browser, http_request 等 |
| 记忆 | `Memory` | SQLite, PostgreSQL, Markdown, Lucid |
| 可观测性 | `Observer` | Noop, Log, Multi, Prometheus, OTel |
| 运行时 | `RuntimeAdapter` | Native, Docker（沙箱） |
| 外设 | `Peripheral` | STM32, RPi GPIO |

### 扩展点

添加新功能的标准路径：

1. **添加 Provider**：在 `src/providers/` 实现 `Provider` Trait，在工厂注册
2. **添加 Channel**：在 `src/channels/` 实现 `Channel` Trait
3. **添加 Tool**：在 `src/tools/` 实现 `Tool` Trait，严格参数校验
4. **添加 Peripheral**：在 `src/peripherals/` 实现 `Peripheral` Trait

### 安全设计

- **默认安全**：Deny-by-default 访问控制
- **沙箱执行**：工作空间隔离、命令白名单
- **密钥管理**：ChaCha20-Poly1305 AEAD 加密存储
- **速率限制**：防止滥用
- **路径遍历防护**：阻止 `/etc`, `/root`, `~/.ssh` 等敏感路径

## 文档系统

### 入口点

- **主 README**：`README.md`（多语言：zh-CN/ja/ru/fr/vi）
- **文档中心**：`docs/README.md`
- **统一目录**：`docs/SUMMARY.md`
- **命令参考**：`docs/commands-reference.md`
- **配置参考**：`docs/config-reference.md`
- **运维手册**：`docs/operations-runbook.md`
- **故障排除**：`docs/troubleshooting.md`

### 文档规范

- 支持的语言：`en`, `zh-CN`, `ja`, `ru`, `fr`, `vi`, `el`
- 修改导航或共享文案时，需同步所有支持语言的入口点
- 使用 `docs/i18n-guide.md` 作为国际化完成检查清单

## 环境变量

```bash
# 核心配置
API_KEY=sk-...              # 通用 API 密钥
PROVIDER=openrouter         # 默认提供商
ZEROCLAW_WORKSPACE=/path    # 工作空间目录

# 提供商特定
OPENROUTER_API_KEY=sk-or-...
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

# 网关
ZEROCLAW_GATEWAY_PORT=42617
ZEROCLAW_GATEWAY_HOST=127.0.0.1
```

## 性能基准

| 指标 | ZeroClaw |
|------|----------|
| 二进制大小 | ~8.8 MB |
| 启动时间 | <10ms |
| 内存占用 | <5MB |
| 支持硬件 | $10 开发板 |

测量方法：
```bash
cargo build --release
/usr/bin/time -l target/release/zeroclaw --help
```

## 贡献指南

### 首次贡献

1. 查找 [`good first issue`](https://github.com/zeroclaw-labs/zeroclaw/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
2. Fork 并创建分支
3. 遵循代码规范
4. 运行测试和 Lint
5. 提交 PR 到 `dev` 分支

### 风险分级

- **低风险**：文档/Chore/仅测试变更
- **中风险**：`src/**` 行为变更（无安全边界影响）
- **高风险**：`src/security/**`, `src/runtime/**`, `src/gateway/**`, `src/tools/**`, CI 工作流

### 隐私要求

- 禁止提交真实姓名、邮箱、电话、API 密钥等敏感信息
- 使用中性占位符：`user_a`, `test_user`, `zeroclaw_bot`, `example.com`
- 测试命名使用 ZeroClaw 专属标签：`ZeroClawAgent`, `zeroclaw_user`

## 相关资源

- **GitHub**：https://github.com/zeroclaw-labs/zeroclaw
- **文档**：https://github.com/zeroclaw-labs/zeroclaw/tree/main/docs
- **官网**：https://zeroclawlabs.ai
- **Telegram**：https://t.me/zeroclawlabs
- **X (Twitter)**：https://x.com/zeroclawlabs
