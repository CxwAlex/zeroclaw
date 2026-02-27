# ZeroClaw 优化方案二：多租户安全隔离系统

> **版本**: v1.0  
> **创建日期**: 2026 年 2 月 27 日  
> **优先级**: P0 - 核心能力  
> **参考项目**: nanoclaw 容器隔离，nullclaw 8 层安全

---

## 一、现状分析

### 1.1 当前 zeroclaw 安全机制

```toml
# config.toml - 现有安全配置
[security.otp]
enabled = false
method = "totp"
gated_actions = ["shell", "file_write", "browser"]

[security.estop]
enabled = false
require_otp_to_resume = true

[gateway]
require_pairing = true
allow_public_bind = false
```

### 1.2 存在的问题

| 问题 | 描述 | 企业影响 |
|------|------|---------|
| **租户隔离弱** | 共享工作空间和记忆 | 数据泄露风险 |
| **权限模型粗粒度** | 仅 OTP 门控动作 | 无法实现 RBAC |
| **审计不完整** | 缺少详细操作日志 | 合规困难 |
| **容器隔离可选** | Docker 运行时非默认 | 生产环境风险 |
| **无租户配额** | 资源使用无限制 | DoS 风险 |

### 1.3 对比 nanoclaw 优势

```typescript
// nanoclaw 每群组独立容器 + CLAUDE.md
groups/
├── main/
│   └── CLAUDE.md      # 主群组内存
├── tenant-a/
│   └── CLAUDE.md      # 租户 A 隔离内存
└── tenant-b/
    └── CLAUDE.md      # 租户 B 隔离内存
```

**优势**: 文件系统级隔离，天然多租户

---

## 二、优化目标

### 2.1 核心能力

| 能力 | 目标描述 |
|------|---------|
| **租户隔离** | 独立工作空间、记忆、配置 |
| **RBAC 权限** | 角色 + 权限细粒度控制 |
| **完整审计** | 所有操作可追溯 |
| **容器默认** | 生产环境默认容器隔离 |
| **资源配额** | 每租户资源限制 |
| **数据加密** | 敏感数据加密存储 |

### 2.2 合规目标

| 标准 | 要求 | 支持情况 |
|------|------|---------|
| SOC 2 | 访问控制、审计日志 | 需增强 |
| GDPR | 数据隔离、删除权 | 需增强 |
| ISO 27001 | 信息安全管理体系 | 需增强 |
| 等保 2.0 | 等级保护要求 | 需增强 |

---

## 三、架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Multi-Tenant Security Layer                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Tenant Manager (租户管理)                    │    │
│  │  - 租户创建/销毁                                         │    │
│  │  - 租户配置隔离                                          │    │
│  │  - 资源配额管理                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              RBAC Engine (权限引擎)                       │    │
│  │  - 角色定义                                              │    │
│  │  - 权限检查                                              │    │
│  │  - 策略评估                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Isolation Layer (隔离层)                          │    │
│  │  - 容器运行时 (Docker/Landlock)                          │    │
│  │  - 文件系统沙箱                                          │    │
│  │  - 网络隔离                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Audit System (审计系统)                           │    │
│  │  - 操作日志                                              │    │
│  │  - 安全事件                                              │    │
│  │  - 合规报告                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Encryption Layer (加密层)                         │    │
│  │  - 密钥管理                                              │    │
│  │  - 数据加密                                              │    │
│  │  - 传输加密                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

#### 3.2.1 Tenant Manager

```rust
// src/security/tenant/manager.rs

pub struct TenantManager {
    /// 租户存储
    tenants: DashMap<String, Tenant>,
    /// 租户模板
    templates: DashMap<String, TenantTemplate>,
    /// 全局配置
    config: TenantConfig,
}

pub struct Tenant {
    pub id: String,
    pub name: String,
    pub status: TenantStatus,
    pub workspace: PathBuf,
    pub config: TenantConfig,
    pub quotas: ResourceQuotas,
    pub created_at: Instant,
    pub encryption_key: EncryptionKey,
}

pub struct TenantConfig {
    /// 独立工作空间
    pub isolated_workspace: bool,
    /// 独立记忆后端
    pub isolated_memory: bool,
    /// 容器隔离
    pub container_isolation: bool,
    /// 网络策略
    pub network_policy: NetworkPolicy,
    /// 审计级别
    pub audit_level: AuditLevel,
}

pub struct ResourceQuotas {
    /// 最大 Agent 数
    pub max_agents: u32,
    /// 最大记忆条目
    pub max_memory_entries: u32,
    /// 最大存储 (MB)
    pub max_storage_mb: u32,
    /// 最大 Token/分钟
    pub max_tokens_per_minute: u32,
    /// 最大 API 调用/分钟
    pub max_api_calls_per_minute: u32,
}

impl TenantManager {
    /// 创建新租户
    pub async fn create_tenant(
        &self,
        name: String,
        template: Option<String>,
        config: TenantConfig,
    ) -> Result<Tenant>;

    /// 销毁租户
    pub async fn delete_tenant(&self, tenant_id: &str, purge: bool) -> Result<()>;

    /// 获取租户隔离的工作空间
    pub fn get_workspace(&self, tenant_id: &str) -> Result<PathBuf>;

    /// 检查租户配额
    pub fn check_quota(&self, tenant_id: &str, resource: ResourceType) -> Result<QuotaStatus>;
}
```

#### 3.2.2 RBAC Engine

```rust
// src/security/rbac/engine.rs

pub struct RBACEngine {
    /// 角色定义
    roles: DashMap<String, Role>,
    /// 用户 - 角色分配
    user_roles: DashMap<String, Vec<String>>,
    /// 租户 - 用户关系
    tenant_users: DashMap<String, Vec<String>>,
    /// 权限策略
    policies: Vec<Policy>,
}

pub struct Role {
    pub name: String,
    pub description: String,
    pub permissions: Vec<Permission>,
    pub inherited_roles: Vec<String>,
}

pub struct Permission {
    /// 资源类型
    pub resource: ResourceType,
    /// 允许的操作
    pub actions: Vec<Action>,
    /// 资源过滤器
    pub resource_filter: Option<ResourceFilter>,
    /// 条件表达式
    pub conditions: Vec<Condition>,
}

pub enum ResourceType {
    Agent,
    Memory,
    File,
    Tool,
    Workflow,
    Channel,
    Config,
}

pub enum Action {
    Create,
    Read,
    Update,
    Delete,
    Execute,
    Admin,
}

pub struct Policy {
    pub id: String,
    pub effect: Effect,  // Allow | Deny
    pub principals: Vec<String>,
    pub resources: Vec<String>,
    pub actions: Vec<Action>,
    pub conditions: Vec<Condition>,
}

impl RBACEngine {
    /// 权限检查
    pub fn check(
        &self,
        tenant_id: &str,
        user_id: &str,
        resource: &str,
        action: Action,
    ) -> PolicyDecision;

    /// 分配角色
    pub fn assign_role(&self, tenant_id: &str, user_id: &str, role: &str) -> Result<()>;

    /// 撤销角色
    pub fn revoke_role(&self, tenant_id: &str, user_id: &str, role: &str) -> Result<()>;

    /// 获取用户权限列表
    pub fn get_effective_permissions(&self, tenant_id: &str, user_id: &str) -> Vec<Permission>;
}
```

#### 3.2.3 Isolation Layer

```rust
// src/security/isolation/mod.rs

pub struct IsolationLayer {
    /// 容器运行时
    runtime: Arc<dyn RuntimeAdapter>,
    /// 文件系统沙箱
    fs_sandbox: Arc<dyn Sandbox>,
    /// 网络策略执行器
    network_enforcer: Arc<NetworkEnforcer>,
}

pub struct ContainerConfig {
    /// 容器镜像
    pub image: String,
    /// 挂载点
    pub mounts: Vec<Mount>,
    /// 环境变量
    pub env: HashMap<String, String>,
    /// 资源限制
    pub resources: ContainerResources,
    /// 网络配置
    pub network: NetworkConfig,
    /// 安全上下文
    pub security_context: SecurityContext,
}

pub struct Mount {
    pub source: PathBuf,
    pub target: PathBuf,
    pub read_only: bool,
    pub propagation: MountPropagation,
}

pub struct SecurityContext {
    /// 非 root 用户
    pub run_as_non_root: bool,
    /// 用户 ID
    pub run_as_user: Option<u32>,
    /// 组 ID
    pub run_as_group: Option<u32>,
    /// 只读根文件系统
    pub read_only_root_fs: bool,
    /// 能力删除
    pub drop_capabilities: Vec<String>,
    /// seccomp 配置
    pub seccomp_profile: Option<SeccompProfile>,
    /// AppArmor 配置
    pub apparmor_profile: Option<String>,
}

impl IsolationLayer {
    /// 在隔离容器中执行 Agent
    pub async fn run_isolated(
        &self,
        tenant_id: &str,
        agent_id: &str,
        config: ContainerConfig,
    ) -> Result<ExecutionResult>;

    /// 创建文件系统沙箱
    pub fn create_fs_sandbox(&self, tenant_id: &str) -> Result<PathBuf>;

    /// 应用网络策略
    pub async fn apply_network_policy(&self, tenant_id: &str, policy: NetworkPolicy) -> Result<()>;
}
```

#### 3.2.4 Audit System

```rust
// src/security/audit/mod.rs

pub struct AuditSystem {
    /// 审计日志存储
    logger: Arc<dyn AuditLogger>,
    /// 事件处理器
    handlers: Vec<Arc<dyn AuditHandler>>,
    /// 配置
    config: AuditConfig,
}

pub struct AuditEvent {
    pub id: String,
    pub timestamp: DateTime<Utc>,
    pub tenant_id: String,
    pub user_id: String,
    pub action: String,
    pub resource: String,
    pub result: AuditResult,
    pub details: serde_json::Value,
    pub source_ip: Option<String>,
    pub session_id: String,
}

pub enum AuditResult {
    Success,
    Failure { reason: String },
    Denied { policy: String },
}

pub trait AuditLogger: Send + Sync {
    fn log(&self, event: AuditEvent) -> Result<()>;
    fn query(&self, filter: AuditFilter) -> Result<Vec<AuditEvent>>;
    fn export(&self, format: ExportFormat) -> Result<Vec<u8>>;
}

pub struct AuditConfig {
    /// 日志级别
    pub log_level: LogLevel,
    /// 存储后端
    pub storage: AuditStorage,
    /// 保留天数
    pub retention_days: u32,
    /// 敏感数据脱敏
    pub mask_sensitive_data: bool,
    /// 实时告警
    pub real_time_alerts: bool,
}

impl AuditSystem {
    /// 记录审计事件
    pub fn log(&self, event: AuditEvent) -> Result<()>;

    /// 记录工具执行
    pub fn log_tool_execution(
        &self,
        tenant_id: &str,
        user_id: &str,
        tool_name: &str,
        args: &serde_json::Value,
        result: &ToolResult,
    ) -> Result<()>;

    /// 记录权限检查
    pub fn log_access_check(
        &self,
        tenant_id: &str,
        user_id: &str,
        resource: &str,
        action: Action,
        allowed: bool,
    ) -> Result<()>;

    /// 生成合规报告
    pub fn generate_compliance_report(
        &self,
        tenant_id: &str,
        period: DateRange,
        standard: ComplianceStandard,
    ) -> Result<ComplianceReport>;
}
```

#### 3.2.5 Encryption Layer

```rust
// src/security/encryption/mod.rs

pub struct EncryptionLayer {
    /// 密钥管理器
    key_manager: Arc<KeyManager>,
    /// 加密配置
    config: EncryptionConfig,
}

pub struct KeyManager {
    /// 主密钥（HSM/KMS）
    master_key: MasterKey,
    /// 租户密钥
    tenant_keys: DashMap<String, DataEncryptionKey>,
    /// 密钥轮换策略
    rotation_policy: KeyRotationPolicy,
}

pub struct EncryptionConfig {
    /// 数据加密算法
    pub data_algorithm: DataAlgorithm,  // AES-256-GCM | ChaCha20-Poly1305
    /// 密钥派生函数
    pub kdf: KdfAlgorithm,              // Argon2id | PBKDF2
    /// 传输加密
    pub transport_encryption: bool,
    /// 字段级加密
    pub field_level_encryption: bool,
    /// 加密字段列表
    pub encrypted_fields: Vec<String>,
}

pub struct EncryptedData {
    pub ciphertext: Vec<u8>,
    pub nonce: Vec<u8>,
    pub key_id: String,
    pub aad: Vec<u8>,
}

impl EncryptionLayer {
    /// 加密数据
    pub fn encrypt(&self, tenant_id: &str, plaintext: &[u8]) -> Result<EncryptedData>;

    /// 解密数据
    pub fn decrypt(&self, tenant_id: &str, encrypted: &EncryptedData) -> Result<Vec<u8>>;

    /// 加密记忆条目
    pub fn encrypt_memory_entry(&self, tenant_id: &str, entry: &MemoryEntry) -> Result<EncryptedMemoryEntry>;

    /// 密钥轮换
    pub fn rotate_keys(&self, tenant_id: &str) -> Result<()>;
}
```

---

## 四、配置设计

### 4.1 租户配置

```toml
# config.toml

[multi_tenant]
# 启用多租户模式
enabled = true

# 默认租户模板
default_template = "standard"

# 租户隔离级别：none | workspace | full
default_isolation_level = "full"

# 租户存储
[multi_tenant.storage]
# 租户数据目录
tenants_dir = "~/.zeroclaw/tenants"
# 每租户独立数据库
per_tenant_database = true

# 租户模板
[multi_tenant.templates.standard]
quotas.max_agents = 50
quotas.max_memory_entries = 10000
quotas.max_storage_mb = 1024
quotas.max_tokens_per_minute = 1000
isolation.container_isolation = true
isolation.audit_level = "detailed"

[multi_tenant.templates.enterprise]
quotas.max_agents = 500
quotas.max_memory_entries = 100000
quotas.max_storage_mb = 10240
quotas.max_tokens_per_minute = 10000
isolation.container_isolation = true
isolation.audit_level = "comprehensive"
encryption.field_level_encryption = true
```

### 4.2 RBAC 配置

```toml
# rbac.toml

# 角色定义
[[roles]]
name = "tenant_admin"
description = "租户管理员"
permissions = [
    { resource = "agent", actions = ["create", "read", "update", "delete", "execute"] },
    { resource = "memory", actions = ["create", "read", "update", "delete"] },
    { resource = "file", actions = ["create", "read", "update", "delete"] },
    { resource = "tool", actions = ["execute"], conditions = [{ field = "tool_name", op = "not_in", value = ["shell", "file_write"] }] },
    { resource = "config", actions = ["read", "update"] },
]

[[roles]]
name = "developer"
description = "开发者角色"
permissions = [
    { resource = "agent", actions = ["create", "read", "update", "execute"] },
    { resource = "memory", actions = ["read"] },
    { resource = "file", actions = ["read", "update"] },
    { resource = "tool", actions = ["execute"], conditions = [{ field = "tool_name", op = "in", value = ["file_read", "web_search", "http_request"] }] },
]

[[roles]]
name = "viewer"
description = "只读角色"
permissions = [
    { resource = "agent", actions = ["read"] },
    { resource = "memory", actions = ["read"] },
    { resource = "file", actions = ["read"] },
]

# 用户 - 角色分配
[[user_assignments]]
tenant_id = "tenant-a"
user_id = "alice@example.com"
roles = ["tenant_admin"]

[[user_assignments]]
tenant_id = "tenant-a"
user_id = "bob@example.com"
roles = ["developer"]

[[user_assignments]]
tenant_id = "tenant-b"
user_id = "charlie@example.com"
roles = ["viewer"]
```

### 4.3 容器隔离配置

```toml
# container.toml

[isolation]
# 默认容器运行时
default_runtime = "docker"

# Docker 配置
[isolation.docker]
# 容器镜像
image = "zeroclaw-agent:latest"
# 非 root 用户
run_as_user = 1000
# 只读根文件系统
read_only_root_fs = true
# 删除的能力
drop_capabilities = ["ALL"]
# 保留的能力
add_capabilities = ["NET_BIND_SERVICE"]
# 内存限制
memory_limit = "512m"
# CPU 限制
cpu_limit = "1.0"
# 进程数限制
pids_limit = 50
# 磁盘配额
storage_quota = "1g"

# 网络策略
[isolation.network]
# 默认策略
default_policy = "deny"
# 允许的外部域名
allowed_domains = ["api.anthropic.com", "api.openai.com", "api.openrouter.ai"]
# 允许的端口
allowed_ports = [443, 80]
# 内部网络隔离
isolate_tenants = true

# Landlock 配置 (Linux)
[isolation.landlock]
enabled = true
# 只读路径
readonly_paths = ["/etc", "/usr", "/bin"]
# 禁止访问路径
denied_paths = ["~/.ssh", "~/.aws", "~/.gnupg", "/etc/shadow"]
# 允许写入路径（每租户独立）
writable_paths = ["~/.zeroclaw/tenants/{tenant_id}/workspace"]
```

### 4.4 审计配置

```toml
# audit.toml

[audit]
# 启用审计
enabled = true

# 日志级别：minimal | standard | detailed | comprehensive
log_level = "detailed"

# 存储配置
[audit.storage]
# 后端类型
backend = "sqlite"
# 数据库路径
database_path = "~/.zeroclaw/audit/audit.db"
# 保留天数
retention_days = 90
# 最大日志条目
max_entries = 1000000

# 敏感数据脱敏
[audit.masking]
enabled = true
# 脱敏字段
masked_fields = ["api_key", "password", "token", "secret"]
# 脱敏方式：hash | redact | truncate
mask_method = "redact"

# 实时告警
[audit.alerts]
enabled = true
# 告警 webhook
webhook_url = "https://hooks.example.com/alert"
# 告警规则
[[audit.alerts.rules]]
name = "privileged_action"
condition = "action IN ['shell', 'file_write'] AND user_role = 'viewer'"
severity = "high"

[[audit.alerts.rules]]
name = "quota_exceeded"
condition = "quota_usage > 0.9"
severity = "medium"

[[audit.alerts.rules]]
name = "failed_auth"
condition = "event_type = 'auth_failure' AND count > 5 IN 5m"
severity = "high"

# 合规报告
[audit.compliance]
# 启用报告生成
enabled = true
# 报告目录
reports_dir = "~/.zeroclaw/audit/reports"
# 报告频率
frequency = "monthly"
# 支持的标准
standards = ["SOC2", "GDPR", "ISO27001"]
```

---

## 五、API 设计

### 5.1 CLI 命令

```bash
# 租户管理
zeroclaw tenant create <name> [--template <template>] [--config <json>]
zeroclaw tenant delete <id> [--purge]
zeroclaw tenant list
zeroclaw tenant status <id>
zeroclaw tenant switch <id>

# RBAC 管理
zeroclaw rbac role create <name> --permissions <json>
zeroclaw rbac role list
zeroclaw rbac role assign <user> --role <role> --tenant <tenant>
zeroclaw rbac role revoke <user> --role <role>
zeroclaw rbac check <user> --resource <resource> --action <action>

# 审计
zeroclaw audit query --tenant <tenant> --from <date> --to <date> [--action <action>]
zeroclaw audit export --format json|csv --output <file>
zeroclaw audit report --standard SOC2|GDPR|ISO27001 --period <month>

# 加密
zeroclaw encryption key-rotate --tenant <tenant>
zeroclaw encryption status
```

### 5.2 HTTP API

```yaml
# POST /api/v1/tenants
# 创建租户
Request:
  name: string
  template: string
  config: TenantConfig

Response:
  tenant_id: string
  status: "active"

---

# DELETE /api/v1/tenants/{id}
# 删除租户
Request:
  purge: boolean

---

# POST /api/v1/rbac/roles/{role}/assign
# 分配角色
Request:
  user_id: string
  tenant_id: string

---

# POST /api/v1/rbac/check
# 权限检查
Request:
  tenant_id: string
  user_id: string
  resource: string
  action: string

Response:
  allowed: boolean
  policy: string | null

---

# GET /api/v1/audit/events
# 查询审计日志
Query:
  tenant_id: string
  from: string
  to: string
  action: string | null
  user_id: string | null

Response:
  events: AuditEvent[]
  total: number

---

# POST /api/v1/audit/reports/{standard}
# 生成合规报告
Request:
  tenant_id: string
  period: DateRange

Response:
  report_id: string
  status: "generating" | "completed"
  download_url: string | null
```

---

## 六、实现计划

### 6.1 阶段划分

| 阶段 | 内容 | 工期 | 依赖 |
|------|------|------|------|
| **Phase 1** | Tenant Manager | 2 周 | - |
| **Phase 2** | RBAC Engine | 2 周 | Phase 1 |
| **Phase 3** | Isolation Layer (容器) | 2 周 | Phase 1 |
| **Phase 4** | Audit System | 2 周 | Phase 1, 2 |
| **Phase 5** | Encryption Layer | 1 周 | Phase 1 |
| **Phase 6** | CLI + HTTP API | 1 周 | Phase 1-5 |
| **Phase 7** | 测试 + 文档 | 1 周 | Phase 1-6 |

**总计**: 11 周

---

## 七、测试策略

### 7.1 安全测试

```rust
#[tokio::test]
async fn test_tenant_isolation() {
    let tenant_a = create_tenant("tenant-a").await;
    let tenant_b = create_tenant("tenant-b").await;

    // 租户 A 无法访问租户 B 的工作空间
    let workspace_a = tenant_manager.get_workspace(&tenant_a.id).unwrap();
    let workspace_b = tenant_manager.get_workspace(&tenant_b.id).unwrap();

    assert_ne!(workspace_a, workspace_b);
    assert!(!workspace_b.starts_with(&workspace_a));
}

#[tokio::test]
async fn test_rbac_deny_by_default() {
    let user = create_user("viewer").await;
    let decision = rbac.check(&user.id, "shell_tool", Action::Execute);

    // 默认拒绝
    assert!(!decision.allowed);
}

#[tokio::test]
async fn test_container_escape_prevention() {
    let config = ContainerConfig {
        read_only_root_fs: true,
        drop_capabilities: vec!["ALL"],
        ..default()
    };

    let result = isolation.run_isolated("tenant-a", "agent-1", config).await;

    // 验证容器配置正确
    assert!(result.config.read_only_root_fs);
    assert!(result.config.drop_capabilities.contains(&"ALL"));
}
```

### 7.2 合规测试

```rust
#[test]
fn test_audit_log_completeness() {
    let events = audit.query(AuditFilter::all()).unwrap();

    // 验证所有敏感操作都有审计日志
    let privileged_actions: Vec<_> = events
        .iter()
        .filter(|e| matches!(e.action.as_str(), "shell" | "file_write" | "browser"))
        .collect();

    assert!(!privileged_actions.is_empty());
    for event in privileged_actions {
        assert!(event.user_id.is_some());
        assert!(event.timestamp.is_some());
        assert!(event.result.is_some());
    }
}
```

---

## 八、风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| 租户数据泄露 | 高 | 低 | 多层隔离 + 加密 + 审计 |
| 权限提升攻击 | 高 | 中 | RBAC + 最小权限原则 |
| 容器逃逸 | 高 | 低 | 多沙箱后端 + 能力删除 |
| 审计日志篡改 | 高 | 低 | 只追加存储 + 签名 |
| 密钥泄露 | 高 | 低 | HSM/KMS + 轮换策略 |

---

## 九、验收标准

### 9.1 功能验收

- [ ] 租户创建/销毁正常
- [ ] 租户间数据完全隔离
- [ ] RBAC 权限检查正确
- [ ] 容器隔离生效
- [ ] 审计日志完整
- [ ] 数据加密存储

### 9.2 合规验收

- [ ] SOC 2 Type I 要求满足
- [ ] GDPR 数据隔离要求满足
- [ ] 审计日志可导出
- [ ] 支持数据删除权

---

## 十、参考资源

- [nanoclaw 容器隔离](../../nanoclaw/src/container-runner.ts)
- [nullclaw 安全层](../../nullclaw/src/security/)
- [ZeroClaw 现有安全模块](src/security/)
- [Docker 安全最佳实践](https://docs.docker.com/engine/security/)
- [RBAC 标准](https://csrc.nist.gov/projects/role-based-access-control)

---

**审批状态**: 待审批  
**负责人**: 待定  
**最后更新**: 2026 年 2 月 27 日
