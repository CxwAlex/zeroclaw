# ZeroClaw 多 Agent 集群架构方案 v5.0 - 企业可观测版

> **版本**: v5.0 - 企业可观测版
> **创建日期**: 2026 年 2 月 28 日
> **优先级**: P0 - 核心能力
> **状态**: 待审批
> **架构理念**: 混合架构 (核心硬实现 + 编排 Skills 化) + A2A 通信 + 四层可观测性 + 分级记忆共享

---

## 一、执行摘要

### 1.1 v5.0 核心优化

基于竞品调研 (OpenAI Swarm / Google ADK / AutoGen / LangGraph) 和 v3.0/v4.0 方案，v5.0 重点优化三大核心能力：

| 优化点 | v4.0 状态 | v5.0 优化 | 竞品参考 |
|--------|---------|---------|---------|
| **Agent 通信** | 团队内通信 | ✅ A2A 协议 + 跨团队通信 | Google ADK A2A |
| **可观测性** | 基础审计日志 | ✅ 四层看板 (董事长/CEO/团队/Agent) | LangGraph 监控 |
| **记忆共享** | 三层记忆 | ✅ 分级共享 (团队→集群→全局) | v3.0 优化 |

### 1.2 核心架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    可观测性层 (Observability)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 董事长看板   │  │ CEO 看板      │  │ 团队看板     │          │
│  │ - 公司概览   │  │ - 项目列表   │  │ - 任务进度   │          │
│  │ - 资源总览   │  │ - 资源使用   │  │ - Agent 状态  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐                                              │
│  │ Agent 看板    │                                              │
│  │ - 执行记录   │                                              │
│  │ - 健康状态   │                                              │
│  └──────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    编排层 (Skills)                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  A2A 通信网关 (Agent-to-Agent Gateway)                   │    │
│  │  - 跨团队消息路由                                        │    │
│  │  - 协议转换                                              │    │
│  │  - 权限验证                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ CEO Skills   │  │ Team Skills  │  │ Worker Skills│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    核心层 (硬实现)                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ ClusterCore  │  │ MemoryCore   │  │ AuditCore    │          │
│  │ + A2A 路由    │  │ + 分级共享    │  │ + 四层指标   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 企业组织类比

```
现实企业              ZeroClaw v5.0
──────────────────────────────────────────────────
董事长            →    用户 (董事长看板)
CEO               →    CEO Agent (CEO 看板)
项目负责人        →    团队负责人 (团队看板)
部门员工          →    Worker Agent (Agent 看板)
──────────────────────────────────────────────────
跨部门会议        →    A2A 跨团队通信
公司知识库        →    全局记忆 (CEO/董事长发起)
部门知识库        →    集群记忆 (团队负责人发起)
团队文档          →    团队记忆 (默认共享)
──────────────────────────────────────────────────
```

---

## 二、Agent 通信机制 (A2A)

### 2.1 设计原则

借鉴 **Google ADK A2A Protocol**，设计 ZeroClaw A2A 通信机制：

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **标准化协议** | 统一消息格式 | A2A Message Schema |
| **按需通信** | 默认团队内，必要时跨团队 | A2A Gateway 路由 |
| **权限控制** | 跨团队需审批 | Skill 权限验证 |
| **可观测性** | 所有通信可追踪 | AuditCore 记录 |

### 2.2 通信层级

```
┌─────────────────────────────────────────────────────────────────┐
│                    L4: 全局通信 (Global)                         │
│  - 董事长/CEO 发起                                               │
│  - 跨实例通信 (多公司)                                          │
│  - 频率：极低 (仅重大事件)                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L3: 集群通信 (Cluster)                        │
│  - CEO/团队负责人发起                                            │
│  - 跨团队通信                                                   │
│  - 频率：低 (项目协作/知识共享)                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L2: 团队通信 (Team)                           │
│  - 团队负责人/Worker 发起                                        │
│  - 团队内部通信                                                 │
│  - 频率：高 (日常协作)                                           │
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

### 2.3 A2A 消息协议

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
    /// 接收者 Agent ID (单播) 或团队 ID (组播)
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
    Query {
        question: String,
    },
    /// 通知 (单向告知)
    Notification {
        title: String,
        body: String,
    },
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
            return Err("权限不足：无法跨团队通信".into());
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
        // 团队内通信：无需审批
        if message.sender_team_id == self.get_team_id(&message.recipient_id) {
            return Ok(true);
        }

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
        // 全局广播：发送到全局队列 (仅 CEO/董事长)
        else if message.recipient_id == "global" {
            let sender_role = self.get_agent_role(&message.sender_id).await?;
            if matches!(sender_role, AgentRole::Ceo | AgentRole::BoardMember) {
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

    /// 标记消息已读
    pub fn mark_as_read(&self, agent_id: &str, message_ids: &[String]) {
        if let Some(mut messages) = self.message_queue.get_mut(agent_id) {
            for msg in messages.iter_mut() {
                if message_ids.contains(&msg.message_id) {
                    // 标记已读标志
                }
            }
        }
    }
}
```

### 2.4 跨团队通信示例

```
场景：产品开发团队 需要 市场调研团队 的数据

产品开发团队负责人 → A2A Gateway
    │
    ├─→ 权限验证 (团队负责人 ✅)
    ├─→ 消息路由 (跨团队 → 市场调研团队)
    └─→ 审计日志 (记录跨团队通信)
        │
        ▼
市场调研团队收件箱
    │
    ├─→ 团队负责人查看消息
    ├─→ 决定：批准共享
    └─→ Worker 执行知识共享
        │
        ▼
产品开发团队收到数据
    │
    └─→ 发送感谢通知 (A2A Response)
```

### 2.5 A2A Skills

```rust
// src/skills/a2a_skills.rs

/// 注册 A2A 通信 Skills
pub fn register_a2a_skills(dispatcher: &SkillDispatcher, gateway: Arc<A2AGateway>) {
    // Skill 1: 发送跨团队消息
    dispatcher.register(SkillDefinition {
        id: "send_cross_team_message".to_string(),
        name: "发送跨团队消息".to_string(),
        description: "向其他团队发送消息，请求协作或共享知识".to_string(),
        parameters: json!({
            "type": "object",
            "properties": {
                "recipient_team_id": {
                    "type": "string",
                    "description": "目标团队 ID"
                },
                "message_type": {
                    "type": "string",
                    "enum": ["query", "notification", "collaboration_request", "knowledge_share"],
                    "description": "消息类型"
                },
                "content": {
                    "type": "object",
                    "description": "消息内容"
                },
                "priority": {
                    "type": "string",
                    "enum": ["low", "normal", "high", "urgent"],
                    "default": "normal",
                    "description": "优先级"
                },
                "requires_reply": {
                    "type": "boolean",
                    "default": false,
                    "description": "是否需要回复"
                }
            },
            "required": ["recipient_team_id", "message_type", "content"]
        }),
        permission: SkillPermission::CeoOrTeamLead,
        executor: Arc::new(SendCrossTeamMessageSkill { gateway }),
    });

    // Skill 2: 查询收件箱
    dispatcher.register(SkillDefinition {
        id: "query_inbox".to_string(),
        name: "查询收件箱".to_string(),
        description: "查询 Agent 或团队的收件箱消息".to_string(),
        parameters: json!({
            "type": "object",
            "properties": {
                "limit": {
                    "type": "integer",
                    "default": 20,
                    "description": "返回消息数量"
                },
                "unread_only": {
                    "type": "boolean",
                    "default": false,
                    "description": "仅返回未读消息"
                }
            }
        }),
        permission: SkillPermission::Public,
        executor: Arc::new(QueryInboxSkill { gateway }),
    });

    // Skill 3: 回复消息
    dispatcher.register(SkillDefinition {
        id: "reply_to_message".to_string(),
        name: "回复消息".to_string(),
        description: "回复收到的 A2A 消息".to_string(),
        parameters: json!({
            "type": "object",
            "properties": {
                "original_message_id": {
                    "type": "string",
                    "description": "原消息 ID"
                },
                "reply_content": {
                    "type": "string",
                    "description": "回复内容"
                },
                "success": {
                    "type": "boolean",
                    "description": "是否成功处理"
                }
            },
            "required": ["original_message_id", "reply_content", "success"]
        }),
        permission: SkillPermission::Public,
        executor: Arc::new(ReplyToMessageSkill { gateway }),
    });
}
```

---

## 三、四层可观测性看板

### 3.1 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                    可观测性数据流                                │
│                                                                  │
│  Agent 执行 ──→ HealthCore ──→ Metrics ──→ Dashboards           │
│      │              │              │              │              │
│      ▼              ▼              ▼              ▼              │
│  执行记录      健康状态      聚合指标      四层看板              │
│  (AuditCore)   (心跳)        (Prometheus)  (Web/Telegram)       │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 四层看板设计

#### L1: 董事长看板 (Board Dashboard)

**用户**: 董事长 (用户本人)
**访问方式**: Telegram / Web Dashboard
**刷新频率**: 实时 / 按需

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
    /// 活跃项目数
    pub active_projects: usize,
    /// 总 Agent 数
    pub total_agents: usize,
    /// 今日完成任务数
    pub tasks_completed_today: usize,
    /// 整体健康度 (0-100)
    pub overall_health_score: f32,
}

/// 资源总览
#[derive(Clone, Serialize, Deserialize)]
pub struct ResourceOverview {
    /// Token 总配额
    pub total_token_quota: usize,
    /// Token 已使用
    pub tokens_used: usize,
    /// Token 剩余
    pub tokens_remaining: usize,
    /// 本月成本 (美分)
    pub cost_this_month_cents: u64,
    /// 成本预算 (美分)
    pub budget_cents: u64,
}

/// 项目摘要
#[derive(Clone, Serialize, Deserialize)]
pub struct ProjectSummary {
    /// 项目 ID
    pub project_id: String,
    /// 项目名称
    pub project_name: String,
    /// 协作模式
    pub pattern: String,
    /// 进度 (0-100%)
    pub progress_percentage: u8,
    /// 健康状态
    pub health_status: String,
    /// 负责人
    pub team_lead: String,
    /// 创建时间
    pub created_at: i64,
}

/// 重大事件
#[derive(Clone, Serialize, Deserialize)]
pub struct MajorEvent {
    /// 事件类型
    pub event_type: String,
    /// 事件描述
    pub description: String,
    /// 影响项目
    pub affected_project: Option<String>,
    /// 时间戳
    pub timestamp: i64,
    /// 严重级别
    pub severity: String,
}
```

**看板内容示例**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ZeroClaw 公司概览
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【公司状态】
✅ 活跃项目：5 个
👥 总 Agent 数：127 个
✅ 今日完成任务：43 个
💚 整体健康度：92/100

【资源使用】
Token: 420 万 / 500 万 (84%)
本月成本：$42.50 / $100.00 (42.5%)
预计月底剩余：$57.50

【项目列表】
1. AI 编程助手市场调研
   进度：████████████░░ 85%  状态：✅ 健康
   负责人：市场研究专家  模式：广撒网并行采集

2. 新产品开发
   进度：████░░░░░░░░░░ 40%  状态：✅ 健康
   负责人：技术负责人  模式：分层审批团队

3. 客户反馈分析
   进度：██░░░░░░░░░░░░ 20%  状态：⚠️ 注意
   负责人：数据分析师  模式：专家会诊

【重大事件 (7 天)】
⚠️ 2026-02-27 客户反馈分析项目 资源申请批准 (+$10)
✅ 2026-02-26 AI 编程助手市场调研项目 完成第一阶段
✅ 2026-02-25 新产品开发项目 启动

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 建议
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- 客户反馈分析项目进度较慢，建议关注
- Token 使用较快，预计 3 天后达到 90%
- 本月成本正常，按当前速度月底剩余 57%
```

---

#### L2: CEO 看板 (CEO Dashboard)

**用户**: CEO Agent
**访问方式**: 内部 API / Skill 调用
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

/// 项目详情
#[derive(Clone, Serialize, Deserialize)]
pub struct ProjectDetail {
    /// 项目 ID
    pub project_id: String,
    /// 项目名称
    pub project_name: String,
    /// 协作模式
    pub pattern: String,
    /// 进度 (0-100%)
    pub progress_percentage: u8,
    /// 健康状态
    pub health_status: HealthStatus,
    /// 团队负责人
    pub team_lead: String,
    /// Worker 数量
    pub worker_count: usize,
    /// 资源配额
    pub quota: ResourceQuota,
    /// 资源使用
    pub usage: ResourceUsage,
    /// 预计完成时间
    pub estimated_completion: Option<i64>,
    /// 里程碑列表
    pub milestones: Vec<Milestone>,
}

/// 待审批事项
#[derive(Clone, Serialize, Deserialize)]
pub struct ApprovalRequest {
    /// 请求 ID
    pub request_id: String,
    /// 请求类型
    pub request_type: String,
    /// 请求者
    pub requester: String,
    /// 请求内容
    pub request_content: Value,
    /// 申请原因
    pub reason: String,
    /// 创建时间
    pub created_at: i64,
    /// 状态
    pub status: String,
}
```

**CEO 看板 API**:

```rust
// src/observability/api.rs

/// CEO 看板 API
pub struct CEODashboardAPI {
    metrics: Arc<MetricsCollector>,
    audit: Arc<AuditLogger>,
    cluster: Arc<ClusterCore>,
    resource: Arc<ResourceCore>,
}

impl CEODashboardAPI {
    /// 获取项目列表
    pub async fn get_projects(&self, filter: Option<ProjectFilter>) -> Vec<ProjectDetail> {
        let teams = self.cluster.get_all_teams();
        let mut projects = Vec::new();

        for team in teams {
            let detail = self.build_project_detail(&team).await;
            if filter.as_ref().map_or(true, |f| f.matches(&detail)) {
                projects.push(detail);
            }
        }

        projects
    }

    /// 获取待审批事项
    pub async fn get_pending_approvals(&self) -> Vec<ApprovalRequest> {
        self.audit.get_pending_approvals().await
    }

    /// 审批资源申请
    pub async fn approve_quota_request(
        &self,
        request_id: &str,
        decision: ApprovalDecision,
    ) -> Result<()> {
        self.resource.process_approval(request_id, decision).await?;
        self.audit.log_approval_decision(request_id, &decision).await;
        Ok(())
    }

    /// 获取团队表现排名
    pub async fn get_team_ranking(&self) -> Vec<TeamPerformance> {
        let teams = self.cluster.get_all_teams();
        let mut performances = Vec::new();

        for team in teams {
            let perf = self.calculate_team_performance(&team).await;
            performances.push(perf);
        }

        performances.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap());
        performances
    }

    /// 计算团队表现分数
    async fn calculate_team_performance(&self, team: &TeamHandle) -> TeamPerformance {
        let usage = self.resource.get_team_usage(&team.id);
        let status = self.cluster.get_team_status(&team.id);

        // 表现分数计算 (0-100)
        let progress_score = status.progress_percentage as f32;
        let efficiency_score = if usage.tokens_quota > 0 {
            (usage.tokens_used as f32 / usage.tokens_quota as f32) * 100.0
        } else {
            0.0
        };
        let health_score = match status.health_status {
            HealthStatus::Healthy => 100.0,
            HealthStatus::Warning => 70.0,
            HealthStatus::Critical => 30.0,
            HealthStatus::Failed => 0.0,
        };

        TeamPerformance {
            team_id: team.id.clone(),
            team_name: team.name.clone(),
            score: (progress_score * 0.5 + efficiency_score * 0.3 + health_score * 0.2),
            progress_percentage: status.progress_percentage,
            efficiency_percentage: efficiency_score as u8,
        }
    }
}
```

---

#### L3: 团队看板 (Team Dashboard)

**用户**: 团队负责人
**访问方式**: 内部 API / Skill 调用
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

/// 任务详情
#[derive(Clone, Serialize, Deserialize)]
pub struct TaskDetail {
    /// 任务 ID
    pub task_id: String,
    /// 任务描述
    pub description: String,
    /// 分配给
    pub assigned_to: String,
    /// 状态
    pub status: TaskStatus,
    /// 进度 (0-100%)
    pub progress_percentage: u8,
    /// 创建时间
    pub created_at: i64,
    /// 预计完成时间
    pub estimated_completion: Option<i64>,
    /// 实际完成时间
    pub completed_at: Option<i64>,
}

/// Worker 状态
#[derive(Clone, Serialize, Deserialize)]
pub struct WorkerStatus {
    /// Agent ID
    pub agent_id: String,
    /// 角色
    pub role: String,
    /// 健康状态
    pub health_status: WorkerHealthStatus,
    /// 当前任务
    pub current_task: Option<String>,
    /// 今日完成任务数
    pub tasks_completed_today: usize,
    /// 最后心跳时间
    pub last_heartbeat: i64,
}
```

**团队看板示例**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 团队看板：AI 编程助手市场调研
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【项目信息】
模式：广撒网并行采集
负责人：市场研究专家
创建时间：2026-02-27 10:00
预计完成：2026-02-27 18:00

【进度】
总体进度：████████████░░ 85%
当前阶段：报告定稿

【任务列表】
✅ 需求分析和搜索策略制定 (完成)
✅ 信息收集 (完成) - 156 条
✅ 信息筛选和验证 (完成) - 89 条
✅ 分析和综合 (完成)
🔄 报告定稿 (进行中) - 负责人处理中

【团队状态】
🟢 市场研究员 A: 健康 | 任务：报告撰写 | 今日完成：5 个
🟢 市场研究员 B: 健康 | 任务：数据整理 | 今日完成：4 个
🟢 数据分析师 A: 健康 | 空闲 | 今日完成：6 个
🟢 数据分析师 B: 健康 | 空闲 | 今日完成：5 个

【资源使用】
Token: 42 万 / 50 万 (84%)
时间：1h45m / 2h (87.5%)
成本：$0.42 / $0.50 (84%)

【团队记忆】
📄 市场规模数据来源列表 (共享)
📄 竞争格局分析模板 (共享)
📄 最佳实践：高效信息搜集方法 (共享)
```

---

#### L4: Agent 看板 (Agent Dashboard)

**用户**: Worker Agent
**访问方式**: 内部 API / 健康检查
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

/// 执行记录
#[derive(Clone, Serialize, Deserialize)]
pub struct ExecutionEntry {
    /// 时间戳
    pub timestamp: i64,
    /// 操作类型
    pub action_type: String,
    /// 操作详情
    pub action_detail: String,
    /// 耗时 (毫秒)
    pub duration_ms: u64,
    /// 结果
    pub result: String,
    /// Token 消耗
    pub tokens_used: usize,
}
```

**Agent 看板示例**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Agent 看板：市场研究员 A
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【Agent 信息】
角色：高级市场研究分析师
所属团队：AI 编程助手市场调研
状态：🟢 健康
创建时间：2026-02-27 10:05

【当前任务】
任务：撰写最终研究报告
进度：████████░░░░ 80%
开始时间：2026-02-27 14:30
预计完成：2026-02-27 16:00

【历史任务 (最近 5 个)】
✅ 信息收集 - 完成 (156 条) - 耗时：25 分钟
✅ 信息筛选和验证 - 完成 (89 条) - 耗时：15 分钟
✅ 竞争格局分析 - 完成 - 耗时：20 分钟
✅ 市场规模估算 - 完成 - 耗时：18 分钟
✅ 增长趋势分析 - 完成 - 耗时：15 分钟

【今日统计】
完成任务数：5 个
总耗时：1h33m
Token 消耗：8.5 万
平均质量评分：4.8/5

【收件箱 (2 未读)】
📨 团队负责人：进度汇报已收到，请继续
📨 数据分析师 B：数据来源已更新，请查阅

【执行记录 (最近 5 条)】
14:35:22 web_search 调用 - 耗时：1.2s - Token: 500 - ✅ 成功
14:33:15 web_fetch 调用 - 耗时：2.5s - Token: 1200 - ✅ 成功
14:30:00 memory_recall 调用 - 耗时：0.3s - Token: 200 - ✅ 成功
14:28:45 任务开始 - 耗时：- - Token: - - ✅ 成功
14:25:00 进度汇报 - 耗时：0.5s - Token: 300 - ✅ 成功
```

---

### 3.3 指标收集与聚合

```rust
// src/observability/metrics.rs

use prometheus::{Registry, Counter, Gauge, Histogram};

/// 指标收集器
pub struct MetricsCollector {
    registry: Registry,
    /// Agent 指标
    agent_count: Gauge,
    agent_health_score: Gauge,
    /// 任务指标
    task_total: Counter,
    task_success: Counter,
    task_failure: Counter,
    task_duration: Histogram,
    /// 资源指标
    token_quota: Gauge,
    token_used: Gauge,
    cost_cents: Counter,
    /// 通信指标
    a2a_messages_sent: Counter,
    a2a_messages_received: Counter,
    a2a_cross_team: Counter,
}

impl MetricsCollector {
    /// 注册指标
    pub fn new() -> Result<Self> {
        let registry = Registry::new();

        let agent_count = Gauge::new("zeroclaw_agents_total", "Total number of agents")?;
        registry.register(Box::new(agent_count.clone()))?;

        let task_total = Counter::new("zeroclaw_tasks_total", "Total number of tasks")?;
        registry.register(Box::new(task_total.clone()))?;

        // ... 注册其他指标

        Ok(Self {
            registry,
            agent_count,
            // ... 初始化其他指标
        })
    }

    /// 记录任务开始
    pub fn record_task_start(&self, task_type: &str) {
        self.task_total.inc();
    }

    /// 记录任务完成
    pub fn record_task_success(&self, duration_secs: f64, tokens_used: usize) {
        self.task_success.inc();
        self.task_duration.observe(duration_secs);
        self.token_used.add(tokens_used as f64);
    }

    /// 记录任务失败
    pub fn record_task_failure(&self, error_type: &str) {
        self.task_failure.inc();
    }

    /// 记录 A2A 消息
    pub fn record_a2a_message(&self, is_cross_team: bool) {
        self.a2a_messages_sent.inc();
        if is_cross_team {
            self.a2a_cross_team.inc();
        }
    }

    /// 导出指标 (Prometheus 格式)
    pub fn gather(&self) -> Vec<prometheus::MetricFamily> {
        self.registry.gather()
    }
}
```

---

## 四、分级记忆共享机制

### 4.1 架构设计 (v3.0 优化)

```
┌─────────────────────────────────────────────────────────────────┐
│                    L4: 全局记忆 (Global)                         │
│  - 发起者：董事长 / CEO                                          │
│  - 内容：公司级最佳实践、重大失败复盘                            │
│  - 访问：所有项目可查询                                          │
│  - 频率：极低 (仅非常有价值的经验)                               │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ CEO/董事长发起
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    L3: 集群记忆 (Cluster)                        │
│  - 发起者：CEO / 团队负责人                                       │
│  - 内容：跨项目经验、模式优化、资源使用统计                      │
│  - 访问：所有团队可查询                                          │
│  - 频率：低 (项目完成后自动/手动共享)                            │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ 团队负责人发起
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    L2: 团队记忆 (Team)                           │
│  - 发起者：团队负责人 / Worker                                   │
│  - 内容：项目文档、中间成果、问题解决方案                        │
│  - 访问：团队内共享                                              │
│  - 频率：高 (默认共享)                                           │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Worker 贡献
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    L1: Worker 记忆 (Individual)                  │
│  - 发起者：Worker Agent                                          │
│  - 内容：当前任务上下文、临时数据                                │
│  - 访问：仅自己                                                  │
│  - 频率：极高 (实时)                                             │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 记忆共享流程

```rust
// src/memory/sharing_v5.rs

/// 记忆共享管理器 (v5.0 优化版)
pub struct MemorySharingManagerV5 {
    /// 全局记忆库
    global_memory: Arc<DashMap<String, GlobalMemoryEntry>>,
    /// 集群记忆库
    cluster_memory: Arc<DashMap<String, ClusterMemoryEntry>>,
    /// 团队记忆库
    team_memory: Arc<DashMap<String, TeamMemoryEntry>>,
    /// 访问控制
    acl: Arc<MemoryACL>,
    /// 审计日志
    audit: Arc<AuditLogger>,
}

/// 全局记忆条目
#[derive(Clone, Serialize, Deserialize)]
pub struct GlobalMemoryEntry {
    /// 条目 ID
    pub id: String,
    /// 经验类型
    pub entry_type: GlobalExperienceType,
    /// 来源项目
    pub source_project: String,
    /// 经验描述
    pub description: String,
    /// 适用场景
    pub applicable_scenarios: Vec<String>,
    /// 可复用模式
    pub reusable_pattern: Option<CollaborationPattern>,
    /// 避免的错误
    pub pitfalls_to_avoid: Vec<String>,
    /// 发起者 (CEO/董事长)
    pub initiated_by: String,
    /// 审批者 (董事长)
    pub approved_by: Option<String>,
    /// 创建时间
    pub created_at: i64,
    /// 被引用次数
    pub citation_count: usize,
    /// 有效性评分 (0-1)
    pub effectiveness_score: f32,
}

#[derive(Clone, Serialize, Deserialize)]
pub enum GlobalExperienceType {
    /// 公司级成功经验
    CompanySuccessStory,
    /// 公司级失败复盘
    CompanyFailureReview,
    /// 公司级最佳实践
    CompanyBestPractice,
    /// 战略级资源统计
    StrategicResourceStatistics,
}

impl MemorySharingManagerV5 {
    /// Worker 贡献知识到团队记忆 (默认共享)
    pub async fn worker_contribute_to_team(
        &self,
        team_id: &str,
        worker_id: &str,
        knowledge: KnowledgeEntry,
    ) -> Result<String> {
        let entry_id = self.create_team_memory_entry(team_id, knowledge).await?;
        self.audit.log_memory_contribution(worker_id, team_id, &entry_id).await;
        Ok(entry_id)
    }

    /// 团队负责人共享到集群记忆
    pub async fn team_lead_share_to_cluster(
        &self,
        team_id: &str,
        team_lead_id: &str,
        knowledge_ids: Vec<String>,
        share_reason: &str,
    ) -> Result<String> {
        // 1. 提取团队记忆
        let entries = self.extract_team_memories(team_id, &knowledge_ids).await?;

        // 2. 创建集群记忆条目
        let cluster_entry = ClusterMemoryEntry {
            id: uuid::Uuid::new_v4().to_string(),
            source_team: team_id.to_string(),
            entries,
            share_reason: share_reason.to_string(),
            initiated_by: team_lead_id.to_string(),
            created_at: chrono::Utc::now().timestamp(),
            citation_count: 0,
            effectiveness_score: 0.5,
        };

        // 3. 存储到集群记忆库
        self.cluster_memory.insert(cluster_entry.id.clone(), cluster_entry);

        // 4. 审计日志
        self.audit.log_memory_share_to_cluster(team_lead_id, team_id, &cluster_entry.id).await;

        Ok(cluster_entry.id.clone())
    }

    /// CEO/董事长共享到全局记忆
    pub async fn ceo_share_to_global(
        &self,
        cluster_entry_id: &str,
        ceo_id: &str,
        share_reason: &str,
    ) -> Result<String> {
        // 1. 获取集群记忆
        let cluster_entry = self.cluster_memory.get(cluster_entry_id)
            .ok_or("集群记忆不存在")?;

        // 2. 评估是否值得共享到全局
        if !self.is_worth_global_sharing(&cluster_entry).await? {
            return Err("该经验不适合共享到全局".into());
        }

        // 3. 创建全局记忆条目
        let global_entry = GlobalMemoryEntry {
            id: uuid::Uuid::new_v4().to_string(),
            entry_type: GlobalExperienceType::CompanyBestPractice,
            source_project: cluster_entry.source_team.clone(),
            description: format!("来自{}团队的最佳实践：{}", cluster_entry.source_team, share_reason),
            applicable_scenarios: self.extract_applicable_scenarios(&cluster_entry).await,
            reusable_pattern: None,
            pitfalls_to_avoid: vec![],
            initiated_by: ceo_id.to_string(),
            approved_by: None, // CEO 可直接决定，或需要董事长审批
            created_at: chrono::Utc::now().timestamp(),
            citation_count: 0,
            effectiveness_score: 0.8,
        };

        // 4. 存储到全局记忆库
        self.global_memory.insert(global_entry.id.clone(), global_entry);

        // 5. 审计日志
        self.audit.log_memory_share_to_global(ceo_id, cluster_entry_id, &global_entry.id).await;

        Ok(global_entry.id.clone())
    }

    /// 查询全局记忆 (所有项目可访问)
    pub async fn query_global_memory(
        &self,
        project_context: &str,
        top_k: usize,
    ) -> Vec<GlobalMemoryEntry> {
        let mut entries: Vec<_> = self.global_memory.iter()
            .map(|e| e.value().clone())
            .collect();

        // 按相关性排序
        entries.sort_by(|a, b| {
            let score_a = self.calculate_global_relevance(a, project_context);
            let score_b = self.calculate_global_relevance(b, project_context);
            score_b.partial_cmp(&score_a).unwrap()
        });

        entries.into_iter().take(top_k).collect()
    }

    /// 评估是否值得共享到全局
    async fn is_worth_global_sharing(&self, entry: &ClusterMemoryEntry) -> Result<bool> {
        // 评估标准:
        // 1. 被引用次数 > 10 (集群内已被多次使用)
        // 2. 有效性评分 > 0.8 (高质量经验)
        // 3. 适用场景广泛 (可复用到多个项目)
        // 4. CEO/董事长认为有价值

        if entry.citation_count < 10 {
            return Ok(false);
        }

        if entry.effectiveness_score < 0.8 {
            return Ok(false);
        }

        let scenarios = self.extract_applicable_scenarios(entry).await;
        if scenarios.len() < 3 {
            return Ok(false);
        }

        Ok(true)
    }
}
```

### 4.3 记忆共享示例

```
场景 1: Worker 贡献到团队记忆 (默认)

Worker Agent (市场研究员):
"我发现了一个新的数据来源，可以获取更准确的市场规模数据。"
    │
    ├─→ 自动贡献到团队记忆
    └─→ 团队内所有 Worker 可见

场景 2: 团队负责人共享到集群记忆

团队负责人:
"我们项目的'高效信息搜集方法'非常有效，建议共享到集群。"
    │
    ├─→ 选择知识条目 (3 个)
    ├─→ 填写共享原因："提升全公司调研效率"
    ├─→ 提交共享申请
    │
    ▼
集群记忆库
    │
    └─→ 所有团队可查询使用

场景 3: CEO 共享到全局记忆

CEO:
"市场调研团队的'高效信息搜集方法'已被 5 个项目使用，
效果显著，决定提升为公司级最佳实践。"
    │
    ├─→ 评估价值 (引用>10, 评分>0.8)
    ├─→ 创建全局记忆条目
    ├─→ 通知所有团队负责人
    │
    ▼
全局记忆库
    │
    └─→ 所有项目默认可查询，新团队自动学习
```

---

## 五、实现计划（12 周）

| 阶段 | 内容 | 工期 | 里程碑 |
|------|------|------|--------|
| **Phase 1** | A2A 通信网关 | 2 周 | M1: 跨团队通信正常 |
| **Phase 2** | 四层看板 (董事长/CEO) | 2 周 | M2: 董事长/CEO 看板可用 |
| **Phase 3** | 四层看板 (团队/Agent) | 1 周 | M3: 团队/Agent 看板可用 |
| **Phase 4** | 指标收集与聚合 | 1 周 | M4: Prometheus 指标正常 |
| **Phase 5** | 分级记忆共享 | 2 周 | M5: 团队→集群→全局共享 |
| **Phase 6** | A2A Skills | 1 周 | M6: A2A Skills 可用 |
| **Phase 7** | 审计追踪增强 | 1 周 | M7: 完整审计日志 |
| **Phase 8** | 测试 + 文档 | 2 周 | M8: 测试覆盖>80% |

**总计**: 12 周

---

## 六、验收标准

### 6.1 A2A 通信验收

- [ ] 团队内通信延迟 <10ms
- [ ] 跨团队通信延迟 <50ms
- [ ] 权限验证正确率 100%
- [ ] 消息投递成功率 >99.9%
- [ ] 审计日志完整记录

### 6.2 可观测性验收

- [ ] 董事长看板数据实时更新
- [ ] CEO 看板 API 响应 <100ms
- [ ] 团队看板 Worker 状态准确
- [ ] Agent 看板执行记录完整
- [ ] Prometheus 指标完整

### 6.3 记忆共享验收

- [ ] 团队内共享默认开启
- [ ] 集群共享需团队负责人发起
- [ ] 全局共享需 CEO/董事长发起
- [ ] 记忆查询相关性排序准确
- [ ] 审计日志记录共享行为

---

## 七、总结

### v5.0 核心优势

| 特性 | v4.0 | v5.0 | 提升 |
|------|------|------|------|
| **Agent 通信** | 团队内 | ✅ A2A+ 跨团队 | 支持企业级协作 |
| **可观测性** | 基础审计 | ✅ 四层看板 | 董事长→Agent 全链路 |
| **记忆共享** | 三层 | ✅ 分级共享 | 团队→集群→全局 |
| **权限控制** | 基础 | ✅ 细粒度 | 跨团队审批 |
| **企业级** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 完全符合企业需求 |

### 企业组织类比

```
现实企业              ZeroClaw v5.0
──────────────────────────────────────────────────
跨部门会议        →    A2A 跨团队通信
公司知识库        →    全局记忆 (CEO/董事长发起)
部门知识库        →    集群记忆 (团队负责人发起)
团队文档          →    团队记忆 (默认共享)
──────────────────────────────────────────────────
董事长看板        →    公司概览/资源总览
CEO 看板          →    项目列表/待审批
团队看板          →    任务进度/Agent 状态
员工看板          →    个人任务/执行记录
──────────────────────────────────────────────────
```

**v5.0 方案实现了真正的企业级多 Agent 集群系统！**

---

**审批状态**: 待审批
**负责人**: 待定
**最后更新**: 2026 年 2 月 28 日
