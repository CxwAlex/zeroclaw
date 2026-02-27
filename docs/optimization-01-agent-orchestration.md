# ZeroClaw 优化方案一：多 Agent 动态编排系统

> **版本**: v1.0  
> **创建日期**: 2026 年 2 月 27 日  
> **优先级**: P0 - 核心能力  
> **参考项目**: nanobot SubagentManager, nanoclaw Agent Swarms

---

## 一、现状分析

### 1.1 当前 zeroclaw 子代理实现

```toml
# config.toml - 静态配置驱动
[agents.researcher]
provider = "openrouter"
model = "anthropic/claude-sonnet-4-6"
system_prompt = "You are a research assistant."
max_depth = 2
agentic = true
allowed_tools = ["web_search", "http_request", "file_read"]
max_iterations = 8

[agents.coder]
provider = "ollama"
model = "qwen2.5-coder:32b"
temperature = 0.2
```

### 1.2 存在的问题

| 问题 | 描述 | 影响 |
|------|------|------|
| **静态配置** | 子代理需预定义，无法运行时创建 | 无法应对动态任务场景 |
| **层级限制** | `max_depth` 硬限制 | 复杂任务分解能力受限 |
| **通信单一** | 仅通过 delegate 工具委托 | 缺少 Agent 间协作机制 |
| **状态不共享** | 各 Agent 独立会话 | 上下文重复，效率低 |
| **无编排引擎** | 缺少工作流定义能力 | 复杂业务流程难以实现 |

### 1.3 对比 nanobot 优势

```python
# nanobot 动态 spawn 子 Agent
async def spawn_subagent(self, name: str, system_prompt: str, tools: list):
    subagent = Subagent(
        name=name,
        system_prompt=system_prompt,
        tools=tools,
        parent=self,
    )
    self.subagents.add(subagent)
    return await subagent.run(user_message)
```

**优势**: 运行时动态创建，灵活适配任务需求

---

## 二、优化目标

### 2.1 核心能力

| 能力 | 目标描述 |
|------|---------|
| **动态创建** | 支持运行时按需创建子 Agent |
| **层级编排** | 支持 N 层嵌套，可配置深度限制 |
| **状态共享** | 可选共享上下文/记忆/工具 |
| **协作通信** | Agent 间消息传递/事件通知 |
| **工作流引擎** | 支持 DAG/状态机定义业务流程 |

### 2.2 性能指标

| 指标 | 目标值 |
|------|-------|
| 子 Agent 创建延迟 | <10ms |
| 并发 Agent 数 | ≥100 |
| 消息传递延迟 | <1ms (本地) |
| 内存占用 | <10MB/Agent |

---

## 三、架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Orchestrator                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Agent Registry (运行时注册表)                │    │
│  │  - 动态创建/销毁                                         │    │
│  │  - 生命周期管理                                          │    │
│  │  - 资源配额追踪                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Message Bus (内部消息总线)                   │    │
│  │  - publish/subscribe                                     │    │
│  │  - 请求/响应模式                                         │    │
│  │  - 广播/组播                                             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Context Manager (共享上下文管理)                  │    │
│  │  - 会话状态共享                                          │    │
│  │  - 记忆访问控制                                          │    │
│  │  - 工具注册表继承                                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Workflow Engine (工作流引擎)                      │    │
│  │  - DAG 定义                                               │    │
│  │  - 状态机                                                │    │
│  │  - 条件分支/并行                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

#### 3.2.1 Agent Registry

```rust
// src/agent/orchestrator/registry.rs

pub struct AgentRegistry {
    /// Agent 实例存储
    agents: DashMap<String, AgentInstance>,
    /// Agent 模板定义
    templates: DashMap<String, AgentTemplate>,
    /// 父子关系追踪
    hierarchy: DashMap<String, Vec<String>>,
    /// 资源配额
    quotas: ResourceQuotas,
}

pub struct AgentTemplate {
    pub name: String,
    pub provider: String,
    pub model: String,
    pub system_prompt: String,
    pub allowed_tools: Vec<String>,
    pub max_iterations: u32,
    pub inherit_context: bool,      // 是否继承父 Agent 上下文
    pub inherit_memory: bool,       // 是否共享记忆
    pub can_spawn: bool,            // 是否允许创建子 Agent
}

pub struct AgentInstance {
    pub template_name: String,
    pub parent_id: Option<String>,
    pub child_ids: Vec<String>,
    pub session: Session,
    pub state: AgentState,
    pub created_at: Instant,
    pub resource_usage: ResourceUsage,
}

impl AgentRegistry {
    /// 动态创建子 Agent
    pub async fn spawn(
        &self,
        parent_id: &str,
        template: AgentTemplate,
        context: Option<SharedContext>,
    ) -> Result<String>;

    /// 销毁 Agent 及其子树
    pub async fn terminate(&self, agent_id: &str, graceful: bool) -> Result<()>;

    /// 获取 Agent 树
    pub fn get_hierarchy(&self, agent_id: &str) -> Vec<String>;
}
```

#### 3.2.2 Message Bus

```rust
// src/agent/orchestrator/bus.rs

pub struct AgentMessageBus {
    /// 广播通道
    broadcast_tx: broadcast::Sender<AgentEvent>,
    /// 点对点通道
    p2p_channels: DashMap<String, mpsc::Sender<Message>>,
    /// 订阅关系
    subscriptions: DashMap<String, Vec<String>>,
}

pub enum AgentEvent {
    /// 任务委托
    Delegate {
        from: String,
        to: String,
        task: Task,
    },
    /// 任务完成
    Completed {
        agent_id: String,
        result: TaskResult,
    },
    /// 状态变更
    StateChanged {
        agent_id: String,
        old_state: AgentState,
        new_state: AgentState,
    },
    /// 上下文更新
    ContextUpdated {
        agent_id: String,
        context_delta: ContextDelta,
    },
}

impl AgentMessageBus {
    /// 发送消息到指定 Agent
    pub async fn send(&self, to: &str, msg: Message) -> Result<()>;

    /// 广播事件
    pub fn broadcast(&self, event: AgentEvent) -> Result<()>;

    /// 订阅事件类型
    pub fn subscribe(&self, agent_id: &str, event_types: Vec<EventType>) -> Receiver<AgentEvent>;
}
```

#### 3.2.3 Context Manager

```rust
// src/agent/orchestrator/context.rs

pub struct SharedContextManager {
    /// 全局上下文存储
    contexts: DashMap<String, SharedContext>,
    /// 访问控制列表
    acl: ContextACL,
}

pub struct SharedContext {
    /// 会话历史（可配置共享比例）
    pub history: Vec<ChatMessage>,
    /// 工作记忆（临时数据）
    pub working_memory: HashMap<String, Value>,
    /// 工具注册表（可继承/隔离）
    pub tools: Arc<ToolRegistry>,
    /// 资源配额
    pub quotas: ResourceQuotas,
}

pub struct ContextACL {
    /// 读权限
    pub read_allowlist: HashMap<String, Vec<String>>,
    /// 写权限
    pub write_allowlist: HashMap<String, Vec<String>>,
}

impl SharedContextManager {
    /// 创建共享上下文
    pub fn create(&self, parent_id: Option<&str>, config: ContextConfig) -> Result<String>;

    /// 访问检查
    pub fn can_access(&self, agent_id: &str, context_id: &str, access: AccessType) -> bool;

    /// 同步上下文状态
    pub async fn sync(&self, agent_id: &str) -> Result<()>;
}
```

#### 3.2.4 Workflow Engine

```rust
// src/agent/orchestrator/workflow.rs

pub struct WorkflowEngine {
    workflows: DashMap<String, WorkflowDefinition>,
    executions: DashMap<String, WorkflowExecution>,
}

/// 工作流定义（DAG）
#[derive(Serialize, Deserialize)]
pub struct WorkflowDefinition {
    pub name: String,
    pub nodes: HashMap<String, WorkflowNode>,
    pub edges: Vec<Edge>,
    pub variables: HashMap<String, Value>,
}

pub struct WorkflowNode {
    pub node_type: NodeType,
    pub agent_template: Option<String>,
    pub condition: Option<Condition>,
    pub parallel: Option<Vec<String>>,
    pub timeout_secs: Option<u64>,
    pub retry_policy: Option<RetryPolicy>,
}

pub enum NodeType {
    /// 单 Agent 执行
    Agent,
    /// 并行执行
    Parallel,
    /// 条件分支
    Condition,
    /// 循环
    Loop,
    /// 人工审批
    Approval,
}

pub struct WorkflowExecution {
    pub workflow_id: String,
    pub current_node: Option<String>,
    pub completed_nodes: HashSet<String>,
    pub variables: HashMap<String, Value>,
    pub state: ExecutionState,
}

impl WorkflowEngine {
    /// 执行工作流
    pub async fn execute(&self, workflow_id: &str, input: Value) -> Result<Value>;

    /// 暂停/恢复
    pub fn pause(&self, execution_id: &str) -> Result<()>;
    pub fn resume(&self, execution_id: &str) -> Result<()>;

    /// 查询状态
    pub fn get_status(&self, execution_id: &str) -> Option<ExecutionStatus>;
}
```

---

## 四、配置设计

### 4.1 新增配置项

```toml
# config.toml

[orchestration]
# 启用编排系统
enabled = true

# 最大并发 Agent 数
max_concurrent_agents = 100

# 默认最大层级深度
max_depth = 5

# Agent 超时（秒）
default_timeout_secs = 300

# 资源配额
[orchestration.quotas]
max_memory_per_agent_mb = 50
max_tool_calls_per_minute = 60
max_tokens_per_request = 8192

# 消息总线配置
[orchestration.bus]
# 广播通道容量
broadcast_capacity = 1000
# P2P 通道容量
p2p_capacity = 100
# 事件保留时间（秒）
event_retention_secs = 60

# 共享上下文配置
[orchestration.context]
# 默认共享模式：none | inherit | full
default_share_mode = "inherit"
# 历史消息共享比例（0.0-1.0）
history_share_ratio = 0.5
# 工作内存大小限制
max_working_memory_entries = 100

# 工作流引擎配置
[orchestration.workflow]
# 启用工作流
enabled = true
# 工作流目录
workflows_dir = "~/.zeroclaw/workflows"
# 最大并发执行数
max_concurrent_executions = 20
# 执行历史保留天数
execution_history_days = 7
```

### 4.2 工作流定义示例

```yaml
# ~/.zeroclaw/workflows/research_report.yaml

name: research_report
description: 生成研究报告的完整工作流
version: "1.0"

variables:
  topic: ""
  depth: "comprehensive"

nodes:
  # 节点 1: 需求分析
  analyze:
    type: agent
    agent_template: analyst
    prompt: "分析用户需求，确定研究范围。主题：{{topic}}"
    output_key: analysis_result

  # 节点 2: 并行信息收集
  collect:
    type: parallel
    nodes:
      - web_search:
          type: agent
          agent_template: researcher
          prompt: "搜索 {{topic}} 相关信息"
          tools: ["web_search", "web_fetch"]
      - db_query:
          type: agent
          agent_template: analyst
          prompt: "查询内部数据库关于 {{topic}} 的记录"
          tools: ["sql_query", "memory_recall"]

  # 节点 3: 条件分支
  validate:
    type: condition
    condition: "{{collect.web_search.result_count}} > 5"
    if_true: synthesize
    if_false: expand_search

  expand_search:
    type: agent
    agent_template: researcher
    prompt: "扩大搜索范围，获取更多关于 {{topic}} 的信息"
    next: synthesize

  # 节点 4: 综合撰写
  synthesize:
    type: agent
    agent_template: writer
    prompt: "基于收集的信息撰写研究报告"
    input_refs: ["analysis_result", "collect"]
    output_key: draft_report

  # 节点 5: 人工审核
  review:
    type: approval
    approvers: ["user@example.com"]
    prompt: "请审核研究报告草稿"
    input_refs: ["draft_report"]

  # 节点 6: 最终润色
  finalize:
    type: agent
    agent_template: editor
    prompt: "根据审核意见润色报告"
    input_refs: ["draft_report", "review.feedback"]

edges:
  - from: analyze
    to: collect
  - from: collect
    to: validate
  - from: validate
    to: synthesize
    condition: "result == true"
  - from: validate
    to: expand_search
    condition: "result == false"
  - from: expand_search
    to: synthesize
  - from: synthesize
    to: review
  - from: review
    to: finalize
```

---

## 五、API 设计

### 5.1 CLI 命令

```bash
# Agent 管理
zeroclaw agent spawn <template> [--parent <id>] [--config <json>]
zeroclaw agent terminate <id> [--graceful]
zeroclaw agent list [--tree]
zeroclaw agent status <id>

# 消息传递
zeroclaw agent send <to> <message>
zeroclaw agent broadcast <event-type> <payload>

# 上下文管理
zeroclaw context create [--parent <id>] [--mode inherit|full|none]
zeroclaw context share <context-id> --with <agent-id>
zeroclaw context sync <agent-id>

# 工作流
zeroclaw workflow run <workflow-id> --input <json>
zeroclaw workflow pause <execution-id>
zeroclaw workflow resume <execution-id>
zeroclaw workflow status <execution-id>
zeroclaw workflow list
```

### 5.2 HTTP API

```yaml
# POST /api/v1/agents/spawn
# 创建子 Agent
Request:
  template: string
  parent_id: string | null
  config: object
  context:
    inherit: boolean
    share_mode: "none" | "inherit" | "full"

Response:
  agent_id: string
  status: "running" | "pending"

---

# DELETE /api/v1/agents/{id}
# 终止 Agent
Request:
  graceful: boolean

---

# GET /api/v1/agents/{id}/hierarchy
# 获取层级关系
Response:
  agent_id: string
  parent: string | null
  children: string[]
  depth: number

---

# POST /api/v1/workflows/{id}/execute
# 执行工作流
Request:
  variables: object
  async: boolean

Response:
  execution_id: string
  status: "running" | "completed" | "failed"

---

# POST /api/v1/agents/{id}/message
# 发送消息到 Agent
Request:
  content: string
  type: "delegate" | "notify" | "query"

Response:
  message_id: string
  status: "sent" | "queued"
```

### 5.3 Rust SDK

```rust
// 使用示例

use zeroclaw::orchestrator::{AgentOrchestrator, AgentTemplate, WorkflowEngine};

#[tokio::main]
async fn main() -> Result<()> {
    let orchestrator = AgentOrchestrator::from_config().await?;

    // 动态创建子 Agent
    let template = AgentTemplate {
        name: "researcher".to_string(),
        provider: "openrouter".to_string(),
        model: "anthropic/claude-sonnet-4-6".to_string(),
        system_prompt: "You are a research assistant.".to_string(),
        allowed_tools: vec!["web_search".to_string(), "web_fetch".to_string()],
        inherit_context: true,
        inherit_memory: true,
        can_spawn: true,
    };

    let agent_id = orchestrator.spawn(&template, None).await?;

    // 发送任务委托
    orchestrator.delegate(
        &agent_id,
        "搜索关于 Rust 异步编程的最新资料",
    ).await?;

    // 订阅事件
    let mut events = orchestrator.subscribe(&agent_id).await?;
    while let Some(event) = events.recv().await {
        match event {
            AgentEvent::Completed { result } => {
                println!("任务完成：{:?}", result);
            }
            _ => {}
        }
    }

    // 执行工作流
    let workflow_engine = orchestrator.workflow_engine();
    let result = workflow_engine
        .execute("research_report", json!({"topic": "Rust async"}))
        .await?;

    Ok(())
}
```

---

## 六、实现计划

### 6.1 阶段划分

| 阶段 | 内容 | 工期 | 依赖 |
|------|------|------|------|
| **Phase 1** | Agent Registry + Message Bus | 2 周 | - |
| **Phase 2** | Context Manager | 1 周 | Phase 1 |
| **Phase 3** | 动态 spawn 工具 | 1 周 | Phase 1, 2 |
| **Phase 4** | Workflow Engine (基础) | 2 周 | Phase 1, 2 |
| **Phase 5** | Workflow Engine (高级) | 2 周 | Phase 4 |
| **Phase 6** | CLI + HTTP API | 1 周 | Phase 1-5 |
| **Phase 7** | 测试 + 文档 | 1 周 | Phase 1-6 |

**总计**: 10 周

### 6.2 里程碑

| 里程碑 | 验收标准 |
|--------|---------|
| M1 (Phase 2) | 可动态创建 Agent，消息传递正常 |
| M2 (Phase 4) | 支持 2 层嵌套，上下文共享正常 |
| M3 (Phase 6) | 工作流可执行，CLI/API 可用 |
| M4 (Phase 7) | 测试覆盖>80%，文档完整 |

---

## 七、测试策略

### 7.1 单元测试

```rust
#[cfg(test)]
mod tests {
    #[tokio::test]
    async fn test_spawn_agent() {
        let registry = AgentRegistry::test_instance();
        let template = create_test_template();

        let agent_id = registry.spawn("parent-1", template, None).await.unwrap();

        assert!(registry.exists(&agent_id));
        assert_eq!(registry.get_parent(&agent_id), Some("parent-1"));
    }

    #[tokio::test]
    async fn test_message_bus_broadcast() {
        let bus = AgentMessageBus::test_instance();
        let mut rx = bus.subscribe("agent-1", vec![EventType::Completed]);

        bus.broadcast(AgentEvent::Completed {
            agent_id: "agent-2".to_string(),
            result: TaskResult::Success("done".to_string()),
        });

        let event = rx.recv().await.unwrap();
        assert!(matches!(event, AgentEvent::Completed { .. }));
    }
}
```

### 7.2 集成测试

```rust
#[tokio::test]
async fn test_agent_hierarchy() {
    let orchestrator = AgentOrchestrator::test_instance();

    // 创建 3 层 Agent 树
    let root = orchestrator.spawn(&root_template, None).await?;
    let child1 = orchestrator.spawn(&child_template, Some(&root)).await?;
    let grandchild = orchestrator.spawn(&grandchild_template, Some(&child1)).await?;

    // 验证层级关系
    let hierarchy = orchestrator.get_hierarchy(&root);
    assert_eq!(hierarchy.depth, 3);
    assert!(hierarchy.contains(&grandchild));

    // 测试消息传递
    orchestrator.send(&grandchild, "Hello").await?;
    // ... 验证消息到达
}
```

### 7.3 性能测试

```rust
#[tokio::test]
async fn benchmark_spawn_latency() {
    let registry = AgentRegistry::test_instance();
    let template = create_minimal_template();

    let start = Instant::now();
    for i in 0..100 {
        registry.spawn("root", template.clone(), None).await?;
    }
    let elapsed = start.elapsed();

    assert!(elapsed < Duration::from_secs(1)); // <10ms/Agent
}

#[tokio::test]
async fn benchmark_message_throughput() {
    let bus = AgentMessageBus::test_instance();

    let start = Instant::now();
    for i in 0..10000 {
        bus.send(&format!("agent-{}", i), Message::text("test")).await?;
    }
    let elapsed = start.elapsed();

    assert!(elapsed < Duration::from_secs(5)); // >2000 msg/s
}
```

---

## 八、风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| 循环 spawn 导致资源耗尽 | 高 | 中 | 实现最大深度检查 + 配额限制 |
| 消息总线成为瓶颈 | 高 | 中 | 使用多通道 + 背压机制 |
| 上下文同步延迟 | 中 | 高 | 增量同步 + 懒加载 |
| 工作流死锁 | 高 | 低 | DAG 验证 + 超时机制 |
| 内存泄漏 | 高 | 中 | 严格生命周期管理 + 泄漏检测 |

---

## 九、验收标准

### 9.1 功能验收

- [ ] 可动态创建/销毁 Agent
- [ ] 支持至少 5 层嵌套
- [ ] 消息传递延迟 <1ms
- [ ] 上下文共享可配置
- [ ] 工作流可定义和执行
- [ ] CLI 和 HTTP API 可用

### 9.2 性能验收

- [ ] Agent 创建延迟 <10ms
- [ ] 支持≥100 并发 Agent
- [ ] 消息吞吐量 >2000 msg/s
- [ ] 内存占用 <10MB/Agent

### 9.3 质量验收

- [ ] 单元测试覆盖 >80%
- [ ] 集成测试通过
- [ ] 性能测试达标
- [ ] 文档完整

---

## 十、参考资源

- [nanobot SubagentManager](../../nanobot/nanobot/agent/subagents.py)
- [nanoclaw Agent Swarms](../../nanoclaw/src/task-scheduler.ts)
- [ZeroClaw 现有 delegate 工具](src/tools/delegate.rs)
- [Tokio 异步模式](https://tokio.rs/tokio/tutorial)
- [Rust DashMap](https://docs.rs/dashmap/latest/dashmap/)

---

**审批状态**: 待审批  
**负责人**: 待定  
**最后更新**: 2026 年 2 月 27 日
