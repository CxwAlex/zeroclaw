# ZeroClaw 多 Agent 集群架构方案 v6.0 - 全局可观测版

> **版本**: v6.0 - 全局可观测架构（五层设计 + A2A 通信 + 四层看板）
> **创建日期**: 2026 年 3 月 1 日
> **优先级**: P0 - 核心能力
> **状态**: 待审批
> **架构理念**: 全局董事长分身 + 企业组织模式 + 核心硬实现 + 编排 Skills 化 + A2A 通信

---

## 一、执行摘要

### 1.1 核心演进

**v6.0 相对 v5.0 的关键升级**:

| 维度 | v5.0 全局编排 | v5.0 企业可观测 | v6.0 全局可观测 | 解决的问题 |
|------|-------------|---------------|---------------|-----------|
| **架构层级** | 四层 (全局/编排/核心/执行) | 四层 (可观测/编排/核心/执行) | **五层** | 多实例 + 可观测性 |
| **用户角色** | 用户 → 董事长分身 → CEO | 董事长 → CEO → 团队 → Agent | **用户 → 董事长 → CEO → 团队 → Agent** | 信息过载 + 角色清晰 |
| **Agent 通信** | 实例内通信 | ✅ A2A 协议 + 跨团队 | ✅ **A2A + 跨实例** | 协作壁垒 |
| **可观测性** | 全局 Dashboard | ✅ 四层看板 | ✅ **五层看板** | 可观测性不足 |
| **实例管理** | 多实例 (分公司) | 单实例 | ✅ **多实例 + 看板** | 规模化扩展 |
| **快速创建** | ✅ CLI/Telegram/Web | ❌ | ✅ **保留** | 使用门槛高 |
| **记忆共享** | ❌ | ✅ 分级共享 | ✅ **四级共享** | 知识孤岛 |

### 1.2 核心架构决策

**问题 1**: 多实例 (分公司) 管理复杂，用户信息过载怎么办？

**答案**: **引入全局董事长 Agent** - 作为用户个人分身，统一管理所有实例

```
用户 (自然人)
    │
    ▼ (唯一交互入口)
┌─────────────────────────────────────────┐
│  董事长 Agent (用户分身)                  │
│  - 启动时自动创建                        │
│  - 管理所有实例 (分公司)                  │
│  - 汇总关键信息                          │
│  - 过滤噪音，只同步重要决策              │
└─────────────────────────────────────────┘
    │
    ├─── 实例 1 (CEO: 市场调研) ──→ Telegram Bot @MarketBot
    ├─── 实例 2 (CEO: 产品开发) ──→ Discord Bot @DevBot
    ├─── 实例 3 (CEO: 客户服务) ──→ Slack Bot
    └─── 实例 N (CEO: ...)
```

**问题 2**: 如何降低使用门槛，快速创建公司 - 团队？

**答案**: **快速创建入口** - CLI/Telegram/Web 多端支持，目标/资源预设

**问题 3**: 如何实现跨团队/跨实例通信？

**答案**: **A2A 通信协议** - 标准化消息格式，权限控制，可观测

**问题 4**: 如何提供完整可观测性？

**答案**: **五层看板** - 用户/董事长/CEO/团队/Agent，每层独立视角

### 1.3 整体架构（五层设计）

```
┌─────────────────────────────────────────────────────────────────┐
│                        可观测层 (Observability)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  用户看板    │  │  董事长看板  │  │  CEO 看板     │          │
│  │  (全局摘要)  │  │  (多实例)    │  │  (项目列表)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │  团队看板    │  │  Agent 看板   │                            │
│  │  (任务进度)  │  │  (执行记录)  │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        全局层 (Global)                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  董事长 Agent (用户分身)                                   │    │
│  │  - 启动时自动创建，绑定用户终端                           │    │
│  │  - 管理所有实例 (分公司)                                  │    │
│  │  - 汇总关键信息，过滤噪音                                 │    │
│  │  - 审批重大决策 (超预算/模式切换/实例创建)                 │    │
│  │  - A2A 全局路由 (跨实例通信)                               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│              ┌───────────────┼───────────────┐                   │
│              ▼               ▼               ▼                   │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│  │   实例 1         │ │   实例 2         │ │   实例 N         │    │
│  │  (市场调研公司)  │ │  (产品开发公司)  │ │  (客户服务公司)  │    │
│  │  CEO + Skills    │ │  CEO + Skills    │ │  CEO + Skills    │    │
│  └────────┬────────┘ └────────┬────────┘ └────────┬────────┘    │
│           │                   │                   │              │
│           ▼                   ▼                   ▼              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              编排层 (Skills) - 每个实例独立                │    │
│  │  ┌──────────────────────────────────────────────────┐   │    │
│  │  │  A2A Gateway (Agent-to-Agent 通信)                │   │    │
│  │  │  - 团队内通信 (L2)                                 │   │    │
│  │  │  - 跨团队通信 (L3)                                 │   │    │
│  │  │  - 跨实例通信 (L4)                                 │   │    │
│  │  │  - 权限验证 + 审计日志                             │   │    │
│  │  └──────────────────────────────────────────────────┘   │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │  CEO Skills  │  │ Team Skills  │  │Worker Skills │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│                              ▼ (Skill 调用核心层 API)             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              核心层 (硬实现) - 每个实例独立                │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │ ClusterCore  │  │ ResourceCore │  │ HealthCore   │   │    │
│  │  │ + A2A 路由    │  │ 原子操作     │  │ 健康检查     │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │ MemoryCore   │  │ MessageCore  │  │ AuditCore    │   │    │
│  │  │ + 分级共享    │  │ 消息路由     │  │ + 四层指标   │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              执行层 (Agent) - 沙箱隔离                     │    │
│  │  - Firecracker 微 VM / Wasm 沙箱 / Docker 容器             │    │
│  │  - MCP 协议调用工具                                       │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 企业组织类比

```
现实企业                  ZeroClaw v6.0
──────────────────────────────────────────────────
投资人/董事长        →    用户 (自然人)
董事长助理          →    董事长 Agent (用户分身)
子公司 CEO          →    实例 CEO Agent
部门负责人          →    团队负责人 Agent
部门员工            →    Worker Agent
──────────────────────────────────────────────────
跨部门会议          →    A2A 跨团队通信 (L3)
跨公司协作          →    A2A 跨实例通信 (L4)
公司知识库          →    全局记忆 (董事长/CEO 发起)
部门知识库          →    集群记忆 (团队负责人发起)
团队文档            →    团队记忆 (默认共享)
──────────────────────────────────────────────────
董事长看板          →    用户/董事长 Dashboard
CEO 办公系统        →    CEO Dashboard
部门看板            →    Team Dashboard
员工工作台          →    Agent Dashboard
──────────────────────────────────────────────────
```

---

## 二、全局层设计

### 2.1 董事长 Agent（用户分身）

**定位**: 用户的 AI 分身，统一管理所有 ZeroClaw 实例

**创建时机**: ZeroClaw 启动时自动创建，绑定用户终端

**双通道通信**:
- ✅ 用户可通过董事长 Agent 下达指令（全局入口）
- ✅ 用户可直接通过 CEO 绑定的 Bot 下达指令（独立通信通道）
- ✅ **双通道并行**，不是只能通过董事长

```rust
// src/agent/chairman.rs

use crate::instance::InstanceHandle;
use dashmap::DashMap;

/// 董事长 Agent - 用户个人分身
pub struct ChairmanAgent {
    /// 用户 ID
    pub user_id: String,
    /// 绑定用户终端（主入口）
    pub user_channel: ChannelId,
    /// 管理的所有实例
    pub instances: DashMap<String, InstanceHandle>,
    /// 全局资源池
    pub global_resource: Arc<GlobalResourceManager>,
    /// 信息聚合器
    pub aggregator: Arc<InformationAggregator>,
    /// 决策过滤器（过滤噪音）
    pub decision_filter: DecisionFilter,
    /// A2A 网关（跨实例通信）
    pub a2a_gateway: Arc<A2AGateway>,
}

/// 实例句柄
#[derive(Clone)]
pub struct InstanceHandle {
    /// 实例 ID
    pub id: String,
    /// 实例名称
    pub name: String,
    /// 实例类型
    pub instance_type: InstanceType,
    /// CEO Agent ID
    pub ceo_agent_id: String,
    /// CEO 绑定的独立通信通道（可选）
    pub ceo_channel: Option<ChannelId>,
    /// 实例状态
    pub status: InstanceStatus,
    /// 资源配额
    pub quota: ResourceQuota,
    /// 当前项目数
    pub active_projects: usize,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 最后活跃时间
    pub last_active_at: DateTime<Utc>,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum InstanceType {
    MarketResearch,
    ProductDevelopment,
    CustomerService,
    DataAnalysis,
    General,
    Custom,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum InstanceStatus {
    Initializing,
    Running,
    Idle,
    Busy,
    Unhealthy,
    Stopped,
}

impl ChairmanAgent {
    /// 启动时自动创建
    pub async fn initialize(user_id: String, user_channel: ChannelId) -> Result<Self> {
        let chairman = Self {
            user_id,
            user_channel,
            instances: DashMap::new(),
            global_resource: Arc::new(GlobalResourceManager::new()),
            aggregator: Arc::new(InformationAggregator::new()),
            decision_filter: DecisionFilter::default(),
            a2a_gateway: Arc::new(A2AGateway::new()),
        };

        chairman.load_existing_instances().await?;
        Ok(chairman)
    }

    /// 创建新实例（分公司）
    pub async fn create_instance(
        &self,
        request: &CreateInstanceRequest,
    ) -> Result<InstanceHandle> {
        // 1. 检查全局资源
        if !self.global_resource.can_allocate(&request.quota) {
            return Err("全局资源不足，请先释放已有实例或申请增加配额".into());
        }

        // 2. 创建实例
        let instance = InstanceHandle {
            id: uuid::Uuid::new_v4().to_string(),
            name: request.name.clone(),
            instance_type: request.instance_type,
            ceo_agent_id: String::new(),
            ceo_channel: request.ceo_channel.clone(), // CEO 独立通信通道
            status: InstanceStatus::Initializing,
            quota: request.quota.clone(),
            active_projects: 0,
            created_at: Utc::now(),
            last_active_at: Utc::now(),
        };

        // 3. 分配全局资源
        self.global_resource.allocate(&request.quota).await?;

        // 4. 创建 CEO Agent
        let ceo = self.create_ceo_agent(&instance, request.ceo_config.clone()).await?;
        let mut instance = instance.clone();
        instance.ceo_agent_id = ceo.id;
        instance.status = InstanceStatus::Running;

        // 5. 注册实例
        self.instances.insert(instance.id.clone(), instance.clone());

        // 6. 通知用户
        self.notify_user(&format!(
            "✅ 已创建新实例「{}」(类型：{:?})\n初始资源：{}\nCEO 已就绪{}",
            instance.name,
            instance.instance_type,
            self.format_quota(&instance.quota),
            instance.ceo_channel.as_ref()
                .map(|c| format!("\n独立通信：{}", c))
                .unwrap_or_default()
        )).await?;

        Ok(instance)
    }

    /// 汇总关键信息（定时任务）
    pub async fn aggregate_and_sync(&self) -> Result<()> {
        let mut summaries = Vec::new();
        for entry in self.instances.iter() {
            let instance = entry.value();
            let summary = self.fetch_instance_summary(instance).await?;
            summaries.push(summary);
        }

        let aggregated = self.aggregator.aggregate(summaries).await?;
        let filtered = self.decision_filter.filter(aggregated);

        if !filtered.is_empty() {
            self.sync_to_user(&filtered).await?;
        }

        Ok(())
    }

    /// 审批重大决策
    pub async fn review_major_decision(
        &self,
        decision: &MajorDecision,
    ) -> Result<DecisionResult> {
        match decision {
            MajorDecision::CreateInstance(request) => {
                let instance = self.create_instance(request).await?;
                Ok(DecisionResult::Approved {
                    message: format!("实例「{}」已创建", instance.name),
                })
            }
            MajorDecision::IncreaseGlobalQuota(request) => {
                self.request_user_confirmation(&format!(
                    "申请增加全局资源配额：{}\n当前配额：{}\n新配额：{}",
                    request.reason,
                    self.global_resource.current_quota(),
                    request.new_quota
                )).await?;
                Ok(DecisionResult::Approved { message: "配额已增加".to_string() })
            }
            MajorDecision::ShutdownInstance(instance_id) => {
                self.shutdown_instance(instance_id).await?;
                Ok(DecisionResult::Approved { message: "实例已关闭".to_string() })
            }
            MajorDecision::MergeInstances { from, to } => {
                self.merge_instances(from, to).await?;
                Ok(DecisionResult::Approved { message: "实例已合并".to_string() })
            }
            MajorDecision::CrossInstanceCollaboration { from, to, purpose } => {
                // 跨实例协作审批
                self.approve_cross_instance_collaboration(from, to, purpose).await?;
                Ok(DecisionResult::Approved { message: "跨实例协作已批准".to_string() })
            }
        }
    }

    /// 查询全局状态
    pub fn get_global_status(&self) -> GlobalStatus {
        let instances: Vec<_> = self.instances.iter().map(|e| e.value().clone()).collect();

        GlobalStatus {
            total_instances: instances.len(),
            running_instances: instances.iter()
                .filter(|i| i.status == InstanceStatus::Running)
                .count(),
            busy_instances: instances.iter()
                .filter(|i| i.status == InstanceStatus::Busy)
                .count(),
            total_projects: instances.iter().map(|i| i.active_projects).sum(),
            global_resource_usage: self.global_resource.get_usage(),
            instances,
        }
    }

    /// 快速创建公司 - 团队入口
    pub async fn quick_create(
        &self,
        request: &QuickCreateRequest,
    ) -> Result<QuickCreateResult> {
        let instance = if let Some(existing) = self.get_instance_by_name(&request.instance_name) {
            existing
        } else {
            self.create_instance(&CreateInstanceRequest {
                name: request.instance_name.clone(),
                instance_type: request.instance_type,
                quota: request.quota.clone(),
                ceo_config: request.ceo_config.clone(),
                ceo_channel: request.ceo_channel.clone(),
            }).await?
        };

        let team = self.invoke_ceo_skill(
            &instance.ceo_agent_id,
            "create_project_team",
            &json!({
                "task": request.task_description,
                "goal": request.team_goal,
                "estimated_complexity": request.complexity,
            }),
        ).await?;

        Ok(QuickCreateResult {
            instance_id: instance.id,
            team_id: team.id,
            message: format!(
                "✅ 已创建「{}」实例和「{}」团队\n目标：{}\n资源：{}",
                instance.name,
                team.name,
                request.team_goal,
                self.format_quota(&team.quota)
            ),
        })
    }

    /// 双通道通信：用户可直接联系 CEO
    pub async fn forward_to_ceo(
        &self,
        instance_id: &str,
        message: &str,
    ) -> Result<String> {
        let instance = self.instances.get(instance_id)
            .ok_or("实例不存在")?;

        // 通过 A2A 网关发送消息到 CEO
        let a2a_message = A2AMessage {
            message_id: uuid::Uuid::new_v4().to_string(),
            sender_id: "user".to_string(),
            sender_team_id: None,
            recipient_id: instance.ceo_agent_id.clone(),
            message_type: A2AMessageType::Notification {
                title: "用户消息".to_string(),
                body: message.to_string(),
            },
            priority: MessagePriority::High,
            timestamp: Utc::now().timestamp(),
            related_task_id: None,
            requires_reply: true,
            timeout_secs: Some(300),
        };

        self.a2a_gateway.send(a2a_message).await
    }
}

/// 创建实例请求
#[derive(Clone, Serialize, Deserialize)]
pub struct CreateInstanceRequest {
    pub name: String,
    pub instance_type: InstanceType,
    pub quota: ResourceQuota,
    pub ceo_config: CEOConfig,
    /// CEO 绑定的独立通信通道（可选）
    pub ceo_channel: Option<ChannelId>,
}

/// 全局资源管理器
pub struct GlobalResourceManager {
    global_token_quota: AtomicUsize,
    global_token_used: AtomicUsize,
    max_instances: AtomicUsize,
    current_instances: AtomicUsize,
}

/// 重大决策类型
pub enum MajorDecision {
    CreateInstance(CreateInstanceRequest),
    IncreaseGlobalQuota(QuotaIncreaseRequest),
    ShutdownInstance(String),
    MergeInstances { from: String, to: String },
    CrossInstanceCollaboration { from: String, to: String, purpose: String },
}

/// 全局状态
#[derive(Clone, Serialize, Deserialize)]
pub struct GlobalStatus {
    pub total_instances: usize,
    pub running_instances: usize,
    pub busy_instances: usize,
    pub total_projects: usize,
    pub global_resource_usage: ResourceUsage,
    pub instances: Vec<InstanceHandle>,
}

/// 快速创建请求
#[derive(Clone, Serialize, Deserialize)]
pub struct QuickCreateRequest {
    pub instance_name: String,
    pub instance_type: InstanceType,
    pub task_description: String,
    pub team_goal: String,
    pub complexity: u8,
    pub quota: ResourceQuota,
    pub ceo_config: CEOConfig,
    pub ceo_channel: Option<ChannelId>,
}

/// 快速创建结果
#[derive(Clone, Serialize, Deserialize)]
pub struct QuickCreateResult {
    pub instance_id: String,
    pub team_id: String,
    pub message: String,
}
```

---

### 2.2 双通道通信设计

**核心设计**: 用户可通过两种方式与 CEO 通信

```
┌─────────────────────────────────────────────────────────────────┐
│                    双通道通信架构                                │
│                                                                  │
│  用户 (自然人)                                                   │
│      │                                                           │
│      ├─── 通道 1: 董事长 Agent (全局入口)                        │
│      │       │                                                   │
│      │       ├─── "创建市场调研公司" → 创建实例                   │
│      │       ├─── "查看全局状态" → 汇总信息                      │
│      │       ├─── "我想做 XX 任务" → 快速创建                    │
│      │       └─── "审批资源申请" → 转发到 CEO                    │
│      │                                                           │
│      └─── 通道 2: CEO 独立 Bot (直接通信)                        │
│              │                                                   │
│              ├─── Telegram Bot @MarketBot → CEO 实例 1            │
│              ├─── Discord Bot @DevBot → CEO 实例 2               │
│              └─── Slack Bot → CEO 实例 3                         │
│                                                                  │
│  优势：                                                          │
│  - 全局视角：通过董事长统一管理所有实例                          │
│  - 灵活通信：可直接联系特定 CEO，无需经过董事长                  │
│  - 信息过滤：董事长过滤噪音，只同步重要决策                      │
│  - 独立性：每个实例 CEO 可独立运行，不依赖董事长                 │
└─────────────────────────────────────────────────────────────────┘
```

**用户视角示例**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
通道 1: 通过董事长 Agent（全局入口）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

用户：我想了解 AI 编程助手市场

董事长 Agent 回复:
✅ 已为您创建「AI 编程助手市场调研公司」
- 类型：市场调研
- 初始资源：50 万 Token, 30 个并发 Agent
- CEO：已就绪
- 独立通信：Telegram Bot @MarketBot

项目已启动，我会在以下情况同步您：
- 项目完成时
- 资源不足需要审批时
- 遇到重大异常时

您也可以直接联系 CEO:
- Telegram: @MarketBot
- 发送："查看项目进展"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
通道 2: 直接联系 CEO（独立通信）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

用户 (Telegram @MarketBot): 查看项目进展

CEO Agent 回复:
━━━━━━━━━━━━━━━━━━━━━━
【项目进展】AI 编程助手市场调研

当前阶段：信息收集
进度：████████░░░░ 65%
团队规模：22 个 Agent

今日完成:
- 收集信息：156 条
- 筛选验证：89 条

预计完成：1 小时 30 分钟

需要我做什么吗？
- "查看详细报告" - 查看当前成果
- "调整方向" - 修改研究重点
- "联系董事长" - 升级到董事长
━━━━━━━━━━━━━━━━━━━━━━
```

---

## 三、A2A 通信协议

### 3.1 设计原则

借鉴 **Google ADK A2A Protocol**，设计 ZeroClaw A2A 通信机制：

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **标准化协议** | 统一消息格式 | A2A Message Schema |
| **按需通信** | 默认团队内，必要时跨团队/跨实例 | A2A Gateway 路由 |
| **权限控制** | 跨团队/跨实例需审批 | Skill 权限验证 |
| **可观测性** | 所有通信可追踪 | AuditCore 记录 |

### 3.2 通信层级

```
┌─────────────────────────────────────────────────────────────────┐
│                    L4: 跨实例通信 (Global)                       │
│  - 董事长/CEO 发起                                               │
│  - 跨实例通信 (多公司协作)                                       │
│  - 频率：极低 (仅重大事件)                                       │
│  - 示例：市场调研公司 → 产品开发公司 (数据共享)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L3: 跨团队通信 (Cluster)                      │
│  - CEO/团队负责人发起                                            │
│  - 同一实例内跨团队通信                                          │
│  - 频率：低 (项目协作/知识共享)                                  │
│  - 示例：信息收集团队 → 数据分析团队                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L2: 团队内通信 (Team)                         │
│  - 团队负责人/Worker 发起                                        │
│  - 团队内部通信                                                 │
│  - 频率：高 (日常协作)                                           │
│  - 示例：市场研究员 A → 市场研究员 B                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L1: Agent 内部 (Internal)                     │
│  - Worker Agent 内部状态                                         │
│  - 工作记忆                                                     │
│  - 频率：极高 (实时)                                             │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 A2A 消息协议

```rust
// src/a2a/protocol.rs

use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A2A 消息 (标准化协议)
#[derive(Clone, Serialize, Deserialize)]
pub struct A2AMessage {
    /// 消息唯一 ID
    pub message_id: String,
    /// 发送者 Agent ID
    pub sender_id: String,
    /// 发送者团队 ID
    pub sender_team_id: Option<String>,
    /// 发送者实例 ID
    pub sender_instance_id: Option<String>,
    /// 接收者 Agent ID (单播) 或团队 ID (组播) 或实例 ID (跨实例)
    pub recipient_id: String,
    /// 消息类型
    pub message_type: A2AMessageType,
    /// 消息内容
    pub content: Value,
    /// 优先级
    pub priority: MessagePriority,
    /// 时间戳
    pub timestamp: i64,
    /// 关联任务 ID (可选)
    pub related_task_id: Option<String>,
    /// 需要回复 (可选)
    pub requires_reply: bool,
    /// 超时时间 (可选，秒)
    pub timeout_secs: Option<u64>,
}

/// 消息类型
#[derive(Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum A2AMessageType {
    /// 查询 (请求信息)
    Query { question: String },
    /// 通知 (单向告知)
    Notification { title: String, body: String },
    /// 请求协作 (需要对方行动)
    CollaborationRequest {
        description: String,
        expected_outcome: String,
        deadline: Option<i64>,
    },
    /// 共享知识 (知识传递)
    KnowledgeShare {
        knowledge_type: String,
        content: String,
        applicable_scenarios: Vec<String>,
    },
    /// 响应 (回复查询/请求)
    Response {
        in_reply_to: String,
        content: String,
        success: bool,
    },
    /// 错误 (通信失败)
    Error {
        in_reply_to: String,
        error_code: String,
        error_message: String,
    },
}

/// 消息优先级
#[derive(Clone, Copy, Serialize, Deserialize, PartialEq, Ord, PartialOrd, Eq)]
#[serde(rename_all = "snake_case")]
pub enum MessagePriority {
    Low = 0,
    Normal = 1,
    High = 2,
    Urgent = 3,
}

/// A2A 通信网关
pub struct A2AGateway {
    /// 消息队列
    message_queue: DashMap<String, Vec<A2AMessage>>,
    /// 订阅关系 (team_id -> [agent_ids])
    subscriptions: DashMap<String, Vec<String>>,
    /// 实例路由 (instance_id -> ceo_id)
    instance_routes: DashMap<String, String>,
    /// 审计日志引用
    audit_logger: Arc<AuditLogger>,
    /// 核心层引用
    core_refs: CoreReferences,
}

impl A2AGateway {
    /// 发送消息
    pub async fn send(&self, message: A2AMessage) -> Result<String> {
        // 1. 权限验证
        if !self.verify_permission(&message).await? {
            return Err("权限不足：无法跨团队/跨实例通信".into());
        }

        // 2. 消息验证
        self.validate_message(&message)?;

        // 3. 路由消息
        self.route_message(&message).await?;

        // 4. 审计日志
        self.audit_logger.log_a2a_message(&message).await;

        Ok(message.message_id.clone())
    }

    /// 权限验证
    async fn verify_permission(&self, message: &A2AMessage) -> Result<bool> {
        // 判断通信层级
        let level = self.determine_communication_level(message);

        match level {
            CommunicationLevel::Internal | CommunicationLevel::Team => {
                // 团队内通信：无需审批
                Ok(true)
            }
            CommunicationLevel::Cluster => {
                // 跨团队通信：需要 CEO 或团队负责人权限
                let sender_role = self.get_agent_role(&message.sender_id).await?;
                match sender_role {
                    AgentRole::Ceo | AgentRole::TeamLead => Ok(true),
                    AgentRole::Worker => {
                        // Worker 跨团队通信需要团队负责人批准
                        self.request_cross_team_approval(&message.sender_id, &message.recipient_id).await
                    }
                }
            }
            CommunicationLevel::Global => {
                // 跨实例通信：需要董事长或 CEO 权限
                let sender_role = self.get_agent_role(&message.sender_id).await?;
                match sender_role {
                    AgentRole::BoardMember | AgentRole::Ceo => Ok(true),
                    _ => {
                        // 需要董事长批准
                        self.request_cross_instance_approval(&message.sender_id, &message.recipient_id).await
                    }
                }
            }
        }
    }

    /// 判断通信层级
    fn determine_communication_level(&self, message: &A2AMessage) -> CommunicationLevel {
        // 同一 Agent → L1
        if message.sender_id == message.recipient_id {
            return CommunicationLevel::Internal;
        }

        // 同一团队 → L2
        if message.sender_team_id == self.get_team_id(&message.recipient_id) {
            return CommunicationLevel::Team;
        }

        // 同一实例 → L3
        if message.sender_instance_id == self.get_instance_id(&message.recipient_id) {
            return CommunicationLevel::Cluster;
        }

        // 跨实例 → L4
        CommunicationLevel::Global
    }

    /// 路由消息
    async fn route_message(&self, message: &A2AMessage) -> Result<()> {
        // 单播：直接发送到目标 Agent 邮箱
        if self.is_agent_id(&message.recipient_id) {
            self.deliver_to_agent(&message.recipient_id, message).await?;
        }
        // 组播：发送到团队广播队列
        else if self.is_team_id(&message.recipient_id) {
            self.broadcast_to_team(&message.recipient_id, message).await?;
        }
        // 跨实例：发送到目标实例 CEO
        else if self.is_instance_id(&message.recipient_id) {
            self.forward_to_instance(&message.recipient_id, message).await?;
        }
        // 全局广播：发送到全局队列 (仅 CEO/董事长)
        else if message.recipient_id == "global" {
            let sender_role = self.get_agent_role(&message.sender_id).await?;
            if matches!(sender_role, AgentRole::BoardMember | AgentRole::Ceo) {
                self.broadcast_global(message).await?;
            } else {
                return Err("权限不足：无法发送全局消息".into());
            }
        }

        Ok(())
    }

    /// 递送到 Agent 邮箱
    async fn deliver_to_agent(&self, agent_id: &str, message: &A2AMessage) -> Result<()> {
        let mut inbox = self.message_queue
            .get_mut(agent_id)
            .or_insert_with(Vec::new);
        inbox.push(message.clone());
        Ok(())
    }

    /// 团队广播
    async fn broadcast_to_team(&self, team_id: &str, message: &A2AMessage) -> Result<()> {
        if let Some(agent_ids) = self.subscriptions.get(team_id) {
            for agent_id in agent_ids.iter() {
                self.deliver_to_agent(agent_id, message).await?;
            }
        }
        Ok(())
    }

    /// 转发到实例
    async fn forward_to_instance(&self, instance_id: &str, message: &A2AMessage) -> Result<()> {
        if let Some(ceo_id) = self.instance_routes.get(instance_id) {
            self.deliver_to_agent(&ceo_id, message).await?;
        }
        Ok(())
    }

    /// 查询 Agent 邮箱
    pub fn get_inbox(&self, agent_id: &str, limit: usize) -> Vec<A2AMessage> {
        if let Some(messages) = self.message_queue.get(agent_id) {
            messages.iter()
                .rev()
                .take(limit)
                .cloned()
                .collect()
        } else {
            Vec::new()
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum CommunicationLevel {
    Internal,
    Team,
    Cluster,
    Global,
}
```

### 3.4 跨实例通信示例

```
场景：产品开发公司 需要 市场调研公司 的数据

产品开发公司 CEO → A2A Gateway
    │
    ├─→ 权限验证 (CEO ✅)
    ├─→ 消息路由 (跨实例 → 市场调研公司 CEO)
    └─→ 审计日志 (记录跨实例通信)
        │
        ▼
市场调研公司 CEO 收件箱
    │
    ├─→ CEO 查看消息
    ├─→ 决定：批准共享
    └─→ 团队负责人执行知识共享
        │
        ▼
产品开发公司收到数据
    │
    └─→ 发送感谢通知 (A2A Response)
```

---

## 四、五层可观测性看板

### 4.1 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                    可观测性数据流                                │
│                                                                  │
│  Agent 执行 ──→ HealthCore ──→ Metrics ──→ Dashboards           │
│      │              │              │              │              │
│      ▼              ▼              ▼              ▼              │
│  执行记录      健康状态      聚合指标      五层看板              │
│  (AuditCore)   (心跳)        (Prometheus)  (Web/Telegram)       │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 五层看板设计

| 层级 | 看板名称 | 用户 | 访问方式 | 刷新频率 |
|------|---------|------|---------|---------|
| **L5** | 用户看板 | 用户 (自然人) | Telegram/Web | 按需 |
| **L4** | 董事长看板 | 董事长 Agent | 内部 API | 实时 (60 秒) |
| **L3** | CEO 看板 | CEO Agent | 内部 API | 实时 |
| **L2** | 团队看板 | 团队负责人 | 内部 API | 实时 |
| **L1** | Agent 看板 | Worker Agent | 内部 API | 实时 |

#### L5: 用户看板 (User Dashboard)

**用户**: 用户 (自然人)
**访问方式**: Telegram / Web Dashboard
**刷新频率**: 按需

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ZeroClaw 全局概览
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【我的公司】
✅ 实例数量：3
🟢 运行中：2  🟡 忙碌：1  ⚪ 空闲：0
📈 活跃项目：5

【资源总览】
Token: 420 万 / 500 万 (84%)
本月成本：$42.50 / $100.00 (42.5%)

【今日完成】
✅ 任务：43 个
📄 报告：3 份
💰 成本：$5.20

【实例列表】
1. AI 编程助手市场调研公司 🟢 运行中
   项目：1  进度：85%  资源：84%

2. 新产品开发公司 🟡 忙碌
   项目：3  进度：40%  资源：45%

3. 客户反馈分析公司 ⚪ 空闲
   项目：0  进度：-  资源：12%

【最近完成】
✅ AI 编程助手市场调研 (质量：4.8/5)
✅ 竞品分析报告 (质量：4.5/5)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 建议
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Token 使用较快，预计 3 天后达到 90%
- 客户反馈分析公司空闲，可考虑关闭释放资源
```

#### L4: 董事长看板 (Board Dashboard)

**用户**: 董事长 Agent
**访问方式**: 内部 API
**刷新频率**: 实时 (60 秒)

```rust
// src/observability/dashboards/board_dashboard.rs

/// 董事长看板数据
#[derive(Clone, Serialize, Deserialize)]
pub struct BoardDashboard {
    /// 公司概览
    pub company_overview: CompanyOverview,
    /// 资源总览
    pub resource_overview: ResourceOverview,
    /// 项目列表 (摘要)
    pub projects_summary: Vec<ProjectSummary>,
    /// 重大事件 (最近 7 天)
    pub major_events: Vec<MajorEvent>,
    /// 成本分析 (本月)
    pub cost_analysis: CostAnalysis,
}

/// 公司概览
#[derive(Clone, Serialize, Deserialize)]
pub struct CompanyOverview {
    /// 实例数量
    pub total_instances: usize,
    /// 活跃项目数
    pub active_projects: usize,
    /// 总 Agent 数
    pub total_agents: usize,
    /// 今日完成任务数
    pub tasks_completed_today: usize,
    /// 整体健康度 (0-100)
    pub overall_health_score: f32,
}
```

#### L3: CEO 看板 (CEO Dashboard)

**用户**: CEO Agent
**访问方式**: 内部 API
**刷新频率**: 实时

```rust
// src/observability/dashboards/ceo_dashboard.rs

/// CEO 看板数据
#[derive(Clone, Serialize, Deserialize)]
pub struct CEODashboard {
    /// 项目列表 (详细)
    pub projects: Vec<ProjectDetail>,
    /// 资源使用详情
    pub resource_usage: ResourceUsageDetail,
    /// 待审批事项
    pub pending_approvals: Vec<ApprovalRequest>,
    /// 团队表现排名
    pub team_performance_ranking: Vec<TeamPerformance>,
    /// 告警列表
    pub alerts: Vec<Alert>,
}
```

#### L2: 团队看板 (Team Dashboard)

**用户**: 团队负责人
**访问方式**: 内部 API
**刷新频率**: 实时

```rust
// src/observability/dashboards/team_dashboard.rs

/// 团队看板数据
#[derive(Clone, Serialize, Deserialize)]
pub struct TeamDashboard {
    /// 项目信息
    pub project_info: ProjectInfo,
    /// 任务列表
    pub tasks: Vec<TaskDetail>,
    /// Worker 状态
    pub worker_statuses: Vec<WorkerStatus>,
    /// 资源使用
    pub resource_usage: ResourceUsage,
    /// 团队记忆
    pub team_knowledge: Vec<KnowledgeEntry>,
}
```

#### L1: Agent 看板 (Agent Dashboard)

**用户**: Worker Agent
**访问方式**: 内部 API
**刷新频率**: 实时

```rust
// src/observability/dashboards/agent_dashboard.rs

/// Agent 看板数据
#[derive(Clone, Serialize, Deserialize)]
pub struct AgentDashboard {
    /// Agent 信息
    pub agent_info: AgentInfo,
    /// 当前任务
    pub current_task: Option<TaskDetail>,
    /// 历史任务 (最近 10 个)
    pub task_history: Vec<TaskSummary>,
    /// 健康状态
    pub health_status: WorkerHealthStatus,
    /// 执行记录
    pub execution_log: Vec<ExecutionEntry>,
    /// 收件箱 (未读消息)
    pub inbox: Vec<A2AMessage>,
}
```

---

## 五、快速创建入口

### 5.1 多端支持

| 入口 | 命令/交互 | 适用场景 |
|------|---------|---------|
| **CLI** | `zeroclaw quick-create --type market --goal "XX"` | 开发者/运维 |
| **Telegram** | `/quick_create market "了解 AI 编程助手市场"` | 日常使用 |
| **Web UI** | 表单填写 + 一键启动 | 企业用户 |
| **HTTP API** | `POST /api/v1/quick-create` | 集成第三方 |

### 5.2 CLI 快速创建

```bash
# 快速创建市场调研公司 - 团队
zeroclaw quick-create \
  --type market-research \
  --name "AI 编程助手调研" \
  --goal "全面了解 AI 编程助手市场规模、竞争格局、增长趋势" \
  --quota-tokens 500000 \
  --quota-agents 30 \
  --complexity 7 \
  --ceo-channel telegram:@MarketBot

# 快速创建产品开发公司 - 团队
zeroclaw quick-create \
  --type product-development \
  --name "新功能开发" \
  --goal "开发 XX 功能，满足 XX 需求" \
  --quota-tokens 1000000 \
  --quota-agents 50 \
  --complexity 8
```

### 5.3 Telegram 快速创建

```
用户：/quick_create market "了解 AI 编程助手市场"

Bot 回复:
━━━━━━━━━━━━━━━━━━━━━━
✅ 快速创建已启动

【实例】AI 编程助手市场调研公司
- 类型：市场调研
- 资源：50 万 Token, 30 个并发 Agent
- 独立通信：Telegram Bot @MarketBot

【团队】AI 编程助手市场调研项目组
- 目标：全面了解 AI 编程助手市场规模、竞争格局、增长趋势
- 协作模式：广撒网并行采集（自动选择）
- 预计完成：2 小时

确认创建？
✅ 确认
❌ 取消
━━━━━━━━━━━━━━━━━━━━━━

用户：✅

Bot 回复:
━━━━━━━━━━━━━━━━━━━━━━
✅ 已创建！

项目已启动，我会在以下情况通知您：
- 项目完成
- 资源不足需要审批
- 重大异常

查看进展：
- 通过董事长：/status
- 直接联系 CEO: @MarketBot
━━━━━━━━━━━━━━━━━━━━━━
```

---

## 六、分级记忆共享

### 6.1 四级记忆架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    L4: 全局记忆 (Global Memory)                   │
│  - 董事长/CEO 发起                                                │
│  - 跨实例共享知识                                                │
│  - 示例：公司最佳实践、跨项目经验                                 │
│  - 访问权限：所有实例 CEO                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L3: 集群记忆 (Cluster Memory)                 │
│  - 团队负责人发起                                                │
│  - 实例内跨团队共享                                              │
│  - 示例：项目复盘、技术方案、问题解决方案                         │
│  - 访问权限：实例内所有 Agent                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L2: 团队记忆 (Team Memory)                    │
│  - Worker 自动贡献                                               │
│  - 团队内共享                                                    │
│  - 示例：工作文档、中间成果、协作记录                             │
│  - 访问权限：团队成员                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L1: 工作记忆 (Working Memory)                 │
│  - Agent 私有                                                    │
│  - 当前任务上下文                                                │
│  - 示例：临时数据、已尝试方案、中间结果                           │
│  - 访问权限：仅当前 Agent                                        │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 记忆共享流程

```rust
// src/memory/sharing.rs

/// 记忆共享管理器
pub struct MemorySharingManager {
    /// 全局经验库
    global_experience: Arc<DashMap<String, ExperienceEntry>>,
    /// 集群知识库
    cluster_knowledge: Arc<DashMap<String, ClusterKnowledge>>,
    /// 团队记忆
    team_memory: Arc<DashMap<String, TeamMemory>>,
    /// 记忆访问统计
    access_stats: DashMap<String, AccessStats>,
}

impl MemorySharingManager {
    /// Worker 贡献知识到团队记忆
    pub async fn worker_contribute(
        &self,
        team_id: &str,
        worker_id: &str,
        knowledge: KnowledgeEntry,
    ) -> Result<()> {
        let mut team = self.team_memory
            .get_mut(team_id)
            .ok_or("团队不存在")?;

        team.entries.push(knowledge);
        team.last_updated = Utc::now();

        // 自动检查是否值得共享到集群
        if self.is_worth_sharing(&knowledge) {
            self.notify_team_lead(team_id, "发现潜在有价值知识，建议共享到集群").await?;
        }

        Ok(())
    }

    /// 团队负责人共享到集群
    pub async fn team_lead_share_to_cluster(
        &self,
        project_id: &str,
        knowledge_ids: Vec<String>,
        share_reason: &str,
    ) -> Result<()> {
        // 创建集群经验条目
        let experience = ExperienceEntry {
            entry_type: ExperienceType::BestPractice,
            source_project: project_id.to_string(),
            description: format!("来自{}项目的经验分享：{}", project_id, share_reason),
            applicable_scenarios: vec![],
            reusable_pattern: None,
            pitfalls_to_avoid: vec![],
            contributor: project_id.to_string(),
            contributed_at: Utc::now(),
            citation_count: 0,
            effectiveness_score: 0.5,
        };

        self.cluster_knowledge.insert(
            format!("{}_{}", project_id, Utc::now().timestamp()),
            experience,
        );

        Ok(())
    }

    /// CEO 共享到全局
    pub async fn ceo_share_to_global(
        &self,
        instance_id: &str,
        knowledge_ids: Vec<String>,
        share_reason: &str,
    ) -> Result<()> {
        // 创建全局经验条目
        let experience = ExperienceEntry {
            entry_type: ExperienceType::SuccessStory,
            source_project: instance_id.to_string(),
            description: format!("来自{}实例的成功经验：{}", instance_id, share_reason),
            applicable_scenarios: vec![],
            reusable_pattern: None,
            pitfalls_to_avoid: vec![],
            contributor: instance_id.to_string(),
            contributed_at: Utc::now(),
            citation_count: 0,
            effectiveness_score: 0.8,
        };

        self.global_experience.insert(
            format!("global_{}_{}", instance_id, Utc::now().timestamp()),
            experience,
        );

        Ok(())
    }

    /// 查询全局经验
    pub async fn query_global_experience(
        &self,
        context: &str,
        top_k: usize,
    ) -> Vec<ExperienceEntry> {
        let mut all_entries: Vec<_> = self.global_experience.iter()
            .map(|e| e.value().clone())
            .collect();

        all_entries.sort_by(|a, b| {
            let score_a = self.calculate_relevance(a, context);
            let score_b = self.calculate_relevance(b, context);
            score_b.partial_cmp(&score_a).unwrap()
        });

        all_entries.into_iter().take(top_k).collect()
    }
}
```

---

## 七、实现计划（14 周）

| 阶段 | 内容 | 工期 | 里程碑 |
|------|------|------|--------|
| **Phase 1** | 全局层 (ChairmanAgent) | 2 周 | M1: 董事长 Agent 完成 |
| **Phase 2** | 全局资源管理 | 1 周 | M2: 全局配额管理完成 |
| **Phase 3** | A2A 通信协议 | 2 周 | M3: A2A Gateway 完成 |
| **Phase 4** | 四层可观测性看板 | 2 周 | M4: Dashboard 完成 |
| **Phase 5** | 快速创建入口 | 2 周 | M5: CLI/Telegram/Web完成 |
| **Phase 6** | 分级记忆共享 | 1 周 | M6: 记忆共享完成 |
| **Phase 7** | 核心层优化 | 1 周 | M7: 性能优化完成 |
| **Phase 8** | 测试 + 文档 | 3 周 | M8: 测试覆盖>80% |

**总计**: 14 周

---

## 八、验收标准

### 8.1 全局层验收

- [ ] 董事长 Agent 启动时自动创建
- [ ] 支持多实例管理（≥10 个实例）
- [ ] 双通道通信正常（董事长/CEO 独立 Bot）
- [ ] 信息聚合定时执行（每 60 秒）
- [ ] 噪音过滤正确率 >90%

### 8.2 A2A 通信验收

- [ ] 团队内通信正常（L2）
- [ ] 跨团队通信正常（L3）
- [ ] 跨实例通信正常（L4）
- [ ] 权限验证正确率 100%
- [ ] 审计日志完整记录

### 8.3 可观测性验收

- [ ] 五层看板数据完整
- [ ] 用户看板 Telegram/Web 可用
- [ ] 董事长看板实时更新
- [ ] CEO/团队/Agent 看板 API 正常
- [ ] 指标聚合延迟 <60 秒

### 8.4 快速创建验收

- [ ] CLI 快速创建命令可用
- [ ] Telegram Bot 快速创建可用
- [ ] Web UI 表单提交可用
- [ ] 创建后 CEO 自动完成后续配置
- [ ] 创建时间 <5 秒

### 8.5 性能验收

- [ ] 全局状态查询 <100ms
- [ ] 快速创建 <5 秒
- [ ] A2A 消息路由 <50ms
- [ ] 单实例性能符合 v4.0 标准

---

## 九、架构对比总结

| 维度 | v4.0 混合 | v5.0 全局编排 | v5.0 企业可观测 | v6.0 全局可观测 |
|------|---------|-------------|---------------|---------------|
| **架构层级** | 三层 | 四层 | 四层 | **五层** |
| **用户角色** | 董事长 | 用户→董事长 | 董事长→CEO | **用户→董事长→CEO** |
| **实例管理** | 单实例 | 多实例 | 单实例 | **多实例** |
| **Agent 通信** | 团队内 | 团队内 | ✅ A2A 跨团队 | ✅ **A2A 跨实例** |
| **可观测性** | 基础 | 全局 Dashboard | ✅ 四层看板 | ✅ **五层看板** |
| **快速创建** | ❌ | ✅ | ❌ | ✅ |
| **双通道** | ❌ | ❌ | ❌ | ✅ |
| **记忆共享** | ❌ | ❌ | ✅ 三级 | ✅ **四级** |
| **性能** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **灵活性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **易用性** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 十、总结

### v6.0 核心优势

| 特性 | 说明 |
|------|------|
| **全局董事长** | 用户分身，统一管理多实例，过滤噪音 |
| **双通道通信** | 可通过董事长或直接联系 CEO，灵活高效 |
| **A2A 通信** | 标准化协议，支持跨团队/跨实例通信 |
| **五层看板** | 用户/董事长/CEO/团队/Agent，完整可观测性 |
| **快速创建** | CLI/Telegram/Web 多端支持，一键启动 |
| **分级记忆** | 全局/集群/团队/工作，四级知识共享 |
| **性能保障** | 核心层硬实现，延续 v4.0 性能优势 |
| **灵活性** | 编排层 Skills 化，动态扩展 |

### 架构演进路线

```
v3.0 企业组织模式
    │
    │ + 核心层硬实现 (性能)
    │ + 编排层 Skills 化 (灵活)
    ▼
v4.0 混合架构
    │
    │ + 全局董事长 (多实例管理)
    │ + 快速创建入口 (易用性)
    ▼
v5.0 全局编排
    │
    │ + A2A 通信协议
    │ + 四层可观测性看板
    │ + 分级记忆共享
    ▼
v5.0 企业可观测
    │
    │ + 双通道通信
    │ + 跨实例 A2A
    │ + 五层看板
    ▼
v6.0 全局可观测架构
```

### 最终定位

**ZeroClaw v6.0** 在 v4.0/v5.0 的基础上，形成了完整的五层架构：

- ✅ **可观测层**: 五层看板，完整可观测性
- ✅ **全局层**: 董事长 Agent，用户分身，多实例管理
- ✅ **编排层**: Skills 化 + A2A 通信，灵活决策
- ✅ **核心层**: 硬实现，性能保障
- ✅ **执行层**: 沙箱隔离，安全执行

**v6.0 实现了性能、灵活性、易用性、可观测性的最佳平衡！**

---

**审批状态**: 待审批
**负责人**: 待定
**最后更新**: 2026 年 3 月 1 日
