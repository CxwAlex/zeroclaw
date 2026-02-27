# ZeroClaw 优化方案三：自定义渠道扩展框架

> **版本**: v1.0  
> **创建日期**: 2026 年 2 月 27 日  
> **优先级**: P0 - 核心能力  
> **参考项目**: nanobot Channel Manager, nanoclaw Channel 接口，nullclaw Channel VTable

---

## 一、现状分析

### 1.1 当前 zeroclaw 渠道支持

| 渠道 | 状态 | 说明 |
|------|------|------|
| `cli` | ✅ | 命令行交互 |
| `telegram` | ✅ | Telegram Bot |
| `discord` | ✅ | Discord Bot |
| `slack` | ✅ | Slack Bot |
| `whatsapp` | ⚠️ | WhatsApp Business API |
| `matrix` | ⚠️ | Matrix (支持 E2EE) |
| `imessage` | ⚠️ | iMessage |
| `email` | ✅ | SMTP/IMAP 邮件 |
| `signal` | ⚠️ | Signal |
| `lark` | ⚠️ | 飞书 |
| `dingtalk` | ⚠️ | 钉钉 |
| `qq` | ⚠️ | QQ |
| `irc` | ⚠️ | IRC |
| `nostr` | ⚠️ | Nostr 协议 |
| `mattermost` | ⚠️ | Mattermost |

### 1.2 存在的问题

| 问题 | 描述 | 企业影响 |
|------|------|---------|
| **企业微信缺失** | 无官方支持 | 国内企业无法使用 |
| **钉钉/飞书功能弱** | 基础消息支持 | 缺少卡片/审批等 |
| **扩展复杂度高** | 需实现完整 Trait | 开发门槛高 |
| **无 SDK 支持** | 缺少辅助库 | 重复造轮子 |
| **测试困难** | 依赖外部服务 | 质量保证难 |

### 1.3 对比 nanobot 优势

```python
# nanobot Channel 基类
class BaseChannel(ABC):
    def __init__(self, config: Any, bus: MessageBus):
        self.config = config
        self.bus = bus

    async def start(self) -> None: ...
    async def stop(self) -> None: ...
    async def send(self, msg: OutboundMessage) -> None: ...

    async def _handle_message(self, sender_id: str, content: str):
        # 统一处理权限检查、消息格式化、发布到总线
        msg = InboundMessage(channel=self.name, ...)
        await self.bus.publish_inbound(msg)
```

**优势**: 统一基类简化开发，消息总线解耦

---

## 二、优化目标

### 2.1 核心能力

| 能力 | 目标描述 |
|------|---------|
| **简化扩展** | 提供 Channel 基类和工具库 |
| **企业渠道** | 企业微信、钉钉、飞书完整支持 |
| **Webhook 支持** | 通用 Webhook 接收器 |
| **SDK 支持** | Rust + Python SDK |
| **热插拔** | 运行时加载/卸载渠道 |
| **统一测试** | Mock 框架和测试工具 |

### 2.2 目标渠道

| 渠道 | 优先级 | 目标完成度 |
|------|--------|-----------|
| 企业微信 | P0 | 消息/卡片/审批 |
| 钉钉 | P0 | 消息/卡片/机器人 |
| 飞书 | P0 | 消息/卡片/机器人 |
| Webhook | P0 | 通用接收器 |
| WebSocket | P1 | 自定义客户端 |
| HTTP Polling | P1 | 通用轮询 |
| 自定义协议 | P2 | 插件框架 |

---

## 三、架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Channel Extension Framework                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Channel Trait (统一接口)                     │    │
│  │  - send() / listen() / health_check()                    │    │
│  │  - typing() / send_media() / send_card()                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Channel Base (抽象基类)                           │    │
│  │  - 消息格式化                                            │    │
│  │  - 权限检查                                              │    │
│  │  - 重试机制                                              │    │
│  │  - 速率限制                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Channel Manager (运行时管理)                      │    │
│  │  - 动态加载/卸载                                         │    │
│  │  - 健康检查                                              │    │
│  │  - 消息路由                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Built-in Channels (内置渠道)                      │    │
│  │  - Telegram / Discord / Slack / ...                      │    │
│  │  - 企业微信 / 钉钉 / 飞书                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Custom Channels (自定义渠道)                      │    │
│  │  - Webhook Channel                                       │    │
│  │  - WebSocket Channel                                     │    │
│  │  - Plugin Channel (.so/.dll 动态加载)                     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

#### 3.2.1 Channel Trait 增强

```rust
// src/channels/mod.rs

#[async_trait]
pub trait Channel: Send + Sync {
    // ========== 基础方法 ==========

    /// 渠道名称
    fn name(&self) -> &str;

    /// 启动监听
    async fn listen(&self, cancel_token: CancellationToken) -> Result<()>;

    /// 发送文本消息
    async fn send(&self, recipient: &str, content: &str) -> Result<()>;

    /// 健康检查
    async fn health_check(&self) -> Result<()>;

    // ========== 增强方法（提供默认实现）==========

    /// 发送富文本消息
    async fn send_rich_text(&self, recipient: &str, content: RichText) -> Result<()> {
        // 默认实现：降级为纯文本
        self.send(recipient, &content.to_plain_text()).await
    }

    /// 发送卡片消息
    async fn send_card(&self, recipient: &str, card: Card) -> Result<()> {
        Err(anyhow::anyhow!("Card not supported"))
    }

    /// 发送媒体文件
    async fn send_media(&self, recipient: &str, media: MediaAttachment) -> Result<()> {
        Err(anyhow::anyhow!("Media not supported"))
    }

    /// 输入指示
    async fn typing(&self, recipient: &str) -> Result<()> {
        Ok(()) // 默认空实现
    }

    /// 回复消息
    async fn reply(&self, original: &IncomingMessage, content: &str) -> Result<()> {
        self.send(&original.sender, content).await
    }

    /// 获取渠道信息
    fn channel_info(&self) -> ChannelInfo {
        ChannelInfo {
            name: self.name().to_string(),
            features: self.supported_features(),
            ..Default::default()
        }
    }

    /// 支持的功能
    fn supported_features(&self) -> ChannelFeatures {
        ChannelFeatures::default()
    }
}

pub struct ChannelFeatures {
    pub supports_cards: bool,
    pub supports_media: bool,
    pub supports_typing: bool,
    pub supports_reactions: bool,
    pub supports_threads: bool,
    pub supports_broadcast: bool,
}
```

#### 3.2.2 Channel Base 抽象基类

```rust
// src/channels/base.rs

pub struct ChannelBase {
    /// 渠道配置
    config: ChannelConfig,
    /// 消息总线
    bus: Arc<MessageBus>,
    /// 速率限制器
    rate_limiter: RateLimiter,
    /// 重试配置
    retry_config: RetryConfig,
    /// 允许列表
    allowlist: Vec<String>,
}

pub struct ChannelConfig {
    pub name: String,
    pub enabled: bool,
    pub max_retries: u32,
    pub retry_delay_ms: u64,
    pub rate_limit_per_minute: u32,
    pub allowlist: Vec<String>,
    pub message_transform: Option<MessageTransform>,
}

impl ChannelBase {
    /// 检查发送者是否在允许列表
    pub fn is_allowed(&self, sender: &str) -> bool {
        self.allowlist.is_empty() || self.allowlist.contains(sender)
    }

    /// 发布消息到总线
    pub async fn publish_to_bus(&self, msg: IncomingMessage) -> Result<()> {
        if !self.is_allowed(&msg.sender) {
            warn!("Message from {} blocked by allowlist", msg.sender);
            return Ok(());
        }
        self.bus.publish_inbound(msg).await
    }

    /// 带重试发送
    pub async fn send_with_retry(&self, recipient: &str, content: &str) -> Result<()> {
        let mut attempts = 0;
        loop {
            match self.send_impl(recipient, content).await {
                Ok(_) => return Ok(()),
                Err(e) if attempts < self.retry_config.max_retries => {
                    attempts += 1;
                    tokio::time::sleep(
                        Duration::from_millis(self.retry_config.delay_ms * attempts as u64)
                    ).await;
                }
                Err(e) => return Err(e),
            }
        }
    }

    /// 速率限制检查
    pub fn check_rate_limit(&self) -> Result<()> {
        self.rate_limiter.check()
    }
}
```

#### 3.2.3 Channel Manager

```rust
// src/channels/manager.rs

pub struct ChannelManager {
    /// 已注册的渠道
    channels: DashMap<String, Arc<dyn Channel>>,
    /// 渠道配置
    configs: DashMap<String, ChannelConfig>,
    /// 动态加载器
    loader: ChannelLoader,
    /// 消息路由
    router: MessageRouter,
}

pub struct ChannelLoader {
    /// 插件目录
    plugin_dir: PathBuf,
    /// 已加载的插件
    plugins: DashMap<String, DynamicLibrary>,
}

pub struct MessageRouter {
    /// 路由规则
    rules: Vec< RoutingRule>,
    /// 默认渠道
    default_channel: Option<String>,
}

impl ChannelManager {
    /// 注册渠道
    pub fn register(&self, name: String, channel: Arc<dyn Channel>) -> Result<()>;

    /// 注销渠道
    pub fn unregister(&self, name: &str) -> Result<()>;

    /// 动态加载插件渠道
    pub async fn load_plugin(&self, plugin_path: &str) -> Result<String>;

    /// 卸载插件渠道
    pub fn unload_plugin(&self, name: &str) -> Result<()>;

    /// 获取渠道
    pub fn get(&self, name: &str) -> Option<Arc<dyn Channel>>;

    /// 列出所有渠道
    pub fn list(&self) -> Vec<ChannelInfo>;

    /// 健康检查
    pub async fn health_check_all(&self) -> Vec<ChannelHealth>;

    /// 启动所有渠道监听
    pub async fn start_all(&self, cancel_token: CancellationToken) -> Result<()>;
}
```

#### 3.2.4 Webhook Channel

```rust
// src/channels/webhook.rs

pub struct WebhookChannel {
    base: ChannelBase,
    /// Webhook 服务器
    server: WebhookServer,
    /// 验证配置
    verification: WebhookVerification,
    /// 消息解析器
    parser: WebhookParser,
}

pub struct WebhookServer {
    host: String,
    port: u16,
    path: String,
    tls: Option<TlsConfig>,
}

pub struct WebhookVerification {
    /// 验证方式
    method: VerificationMethod,
    /// 验证 token
    token: String,
    /// 签名密钥
    signing_secret: Option<String>,
}

pub enum VerificationMethod {
    /// Query 参数验证
    QueryParam { param: String },
    /// Header 验证
    Header { header: String },
    /// 签名验证
    Signature { algorithm: SignatureAlgorithm },
}

pub trait WebhookParser: Send + Sync {
    /// 解析入站消息
    fn parse_message(&self, payload: serde_json::Value) -> Result<IncomingMessage>;

    /// 解析用户 ID
    fn parse_sender(&self, payload: &serde_json::Value) -> Result<String>;

    /// 解析回复目标
    fn parse_reply_target(&self, payload: &serde_json::Value) -> Option<String>;
}

impl WebhookChannel {
    /// 创建通用 Webhook 渠道
    pub fn new(config: WebhookConfig, parser: Box<dyn WebhookParser>) -> Result<Self>;
}

// 内置解析器
pub struct GenericParser;
pub struct SlackParser;
pub struct DingTalkParser;
pub struct WeComParser;
pub struct FeishuParser;
```

#### 3.2.5 企业渠道实现

```rust
// src/channels/wecom.rs (企业微信)

pub struct WeComChannel {
    base: ChannelBase,
    /// 企业 ID
    corp_id: String,
    /// 应用 ID
    agent_id: String,
    /// 应用密钥
    agent_secret: String,
    /// 访问 token
    access_token: RwLock<Option<AccessToken>>,
    /// HTTP 客户端
    client: reqwest::Client,
}

struct AccessToken {
    token: String,
    expires_at: Instant,
}

impl WeComChannel {
    /// 获取访问 token（自动刷新）
    async fn get_access_token(&self) -> Result<String> {
        let cached = self.access_token.read().await;
        if let Some(token) = cached.as_ref() {
            if token.expires_at > Instant::now() + Duration::from_secs(300) {
                return Ok(token.token.clone());
            }
        }
        drop(cached);

        // 刷新 token
        let new_token = self.refresh_token().await?;
        *self.access_token.write().await = Some(new_token.clone());
        Ok(new_token.token)
    }

    /// 发送文本消息
    async fn send_text(&self, user_ids: &[String], content: &str) -> Result<()> {
        let token = self.get_access_token().await?;
        let payload = json!({
            "touser": user_ids.join("|"),
            "msgtype": "text",
            "agentid": self.agent_id,
            "text": { "content": content }
        });

        let resp = self.client
            .post(format!("https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={}", token))
            .json(&payload)
            .send()
            .await?;

        let result: WeComResponse = resp.json().await?;
        if result.errcode != 0 {
            return Err(anyhow::anyhow!("WeCom API error: {}", result.errmsg));
        }
        Ok(())
    }

    /// 发送卡片消息（Markdown）
    async fn send_markdown(&self, user_ids: &[String], content: &str) -> Result<()> {
        // 企业微信支持 Markdown 卡片
        let token = self.get_access_token().await?;
        let payload = json!({
            "touser": user_ids.join("|"),
            "msgtype": "markdown",
            "agentid": self.agent_id,
            "markdown": { "content": content }
        });
        // ... 发送逻辑
    }

    /// 发送卡片消息（富文本）
    async fn send_card(&self, recipient: &str, card: Card) -> Result<()> {
        // 转换为企微卡片格式
        let wecom_card = self.convert_to_wecom_card(card);
        // ... 发送逻辑
    }
}

#[async_trait]
impl Channel for WeComChannel {
    fn name(&self) -> &str { "wecom" }

    async fn send(&self, recipient: &str, content: &str) -> Result<()> {
        self.send_text(&[recipient.to_string()], content).await
    }

    async fn send_card(&self, recipient: &str, card: Card) -> Result<()> {
        self.send_card(recipient, card).await
    }

    async fn listen(&self, cancel_token: CancellationToken) -> Result<()> {
        // 企业微信使用回调模式
        self.start_callback_server(cancel_token).await
    }

    async fn health_check(&self) -> Result<()> {
        self.get_access_token().await?;
        Ok(())
    }
}
```

---

## 四、配置设计

### 4.1 渠道配置

```toml
# config.toml

[[channels.wecom]]
name = "wecom-primary"
corp_id = "ww1234567890"
agent_id = "1000001"
agent_secret = "${WECOM_AGENT_SECRET}"
# 允许的用户
allow_users = ["zhangsan", "lisi"]
# 允许的部门
allow_departments = [1, 2, 3]
# 消息速率限制
rate_limit_per_minute = 60
# 启用卡片消息
enable_cards = true

[[channels.dingtalk]]
name = "dingtalk-primary"
app_key = "ding123456"
app_secret = "${DINGTALK_APP_SECRET}"
# 机器人 webhook（可选，用于群消息）
webhook_url = "https://oapi.dingtalk.com/robot/send?access_token=..."
# 签名密钥
sign_secret = "${DINGTALK_SIGN_SECRET}"
allow_users = ["zhangsan", "lisi"]

[[channels.feishu]]
name = "feishu-primary"
app_id = "cli_a1b2c3d4e5"
app_secret = "${FEISHU_APP_SECRET}"
# 验证 token
verification_token = "${FEISHU_VERIFICATION_TOKEN}"
# 加密密钥（可选）
encrypt_key = "${FEISHU_ENCRYPT_KEY}"
allow_users = ["zhangsan", "lisi"]

# 通用 Webhook 渠道
[[channels.webhook]]
name = "webhook-generic"
host = "0.0.0.0"
port = 9090
path = "/webhook/zeroclaw"
# 验证方式
verification.method = "signature"
verification.signing_secret = "${WEBHOOK_SIGN_SECRET}"
# 使用的解析器
parser = "generic"
# 或者使用内置解析器
# parser = "slack" | "dingtalk" | "wecom" | "feishu"
```

### 4.2 动态插件配置

```toml
# channels.toml

# 插件目录
[channels.plugins]
enabled = true
plugin_dir = "~/.zeroclaw/channels"

# 加载的插件
[[channels.plugins.load]]
name = "custom-crm"
path = "~/.zeroclaw/channels/libcustom_crm.so"
config = { api_url = "https://crm.example.com", api_key = "${CRM_API_KEY}" }

[[channels.plugins.load]]
name = "internal-im"
path = "~/.zeroclaw/channels/libinternal_im.so"
config = { server = "im.internal:8080" }
```

---

## 五、SDK 设计

### 5.1 Rust SDK

```rust
// zeroclaw-channel-sdk

use zeroclaw_channel::{Channel, ChannelBuilder, IncomingMessage, OutboundMessage};

// 快速创建渠道
let channel = ChannelBuilder::new("wecom")
    .config("corp_id", "ww123456")
    .config("agent_id", "1000001")
    .config("agent_secret", env!("WECOM_SECRET"))
    .build()?;

// 发送消息
channel.send("user1", "Hello from ZeroClaw!").await?;

// 发送卡片
let card = Card::markdown("# Title\n\nContent here")
    .add_button("查看", "https://example.com");
channel.send_card("user1", card).await?;

// 监听消息
let mut stream = channel.listen_stream();
while let Some(msg) = stream.next().await {
    println!("收到消息：{:?}", msg);
    channel.reply(&msg, "已收到").await?;
}
```

### 5.2 Python SDK

```python
# zeroclaw-channel-sdk (Python)

from zeroclaw_channel import Channel, ChannelBuilder

# 创建渠道
channel = ChannelBuilder.create("wecom", {
    "corp_id": "ww123456",
    "agent_id": "1000001",
    "agent_secret": os.environ["WECOM_SECRET"]
})

# 发送消息
await channel.send("user1", "Hello from ZeroClaw!")

# 发送卡片
card = Card.markdown("# Title\n\nContent") \
    .add_button("查看", "https://example.com")
await channel.send_card("user1", card)

# 监听消息
async for msg in channel.listen():
    print(f"收到消息：{msg}")
    await channel.reply(msg, "已收到")
```

### 5.3 渠道开发模板

```rust
// 渠道开发模板 (cargo generate)

use zeroclaw_channel::{Channel, ChannelBase, IncomingMessage};

pub struct MyCustomChannel {
    base: ChannelBase,
    // 自定义字段
    api_client: MyApiClient,
}

#[async_trait]
impl Channel for MyCustomChannel {
    fn name(&self) -> &str {
        "my_custom"
    }

    async fn send(&self, recipient: &str, content: &str) -> Result<()> {
        // 实现发送逻辑
        self.api_client.send(recipient, content).await?;
        Ok(())
    }

    async fn listen(&self, cancel_token: CancellationToken) -> Result<()> {
        // 实现监听逻辑
        loop {
            tokio::select! {
                msg = self.api_client.recv() => {
                    let incoming = self.parse_message(msg?)?;
                    self.base.publish_to_bus(incoming).await?;
                }
                _ = cancel_token.cancelled() => break,
            }
        }
        Ok(())
    }

    async fn health_check(&self) -> Result<()> {
        self.api_client.ping().await?;
        Ok(())
    }
}
```

---

## 六、API 设计

### 6.1 CLI 命令

```bash
# 渠道管理
zeroclaw channel list
zeroclaw channel status <name>
zeroclaw channel health-check [--all]

# 动态加载
zeroclaw channel load-plugin <path> [--config <json>]
zeroclaw channel unload-plugin <name>

# 测试
zeroclaw channel test <name> send <recipient> <message>
zeroclaw channel test <name> webhook --payload <json>

# 渠道开发
zeroclaw channel new <name> --template rust|python
zeroclaw channel build <name>
zeroclaw channel package <name>
```

### 6.2 HTTP API

```yaml
# GET /api/v1/channels
# 列出所有渠道
Response:
  channels:
    - name: string
      type: string
      status: "connected" | "disconnected" | "error"
      features: ChannelFeatures

---

# POST /api/v1/channels
# 注册新渠道
Request:
  name: string
  type: string
  config: object

---

# DELETE /api/v1/channels/{name}
# 注销渠道

---

# POST /api/v1/channels/{name}/test
# 测试渠道
Request:
  test_type: "send" | "webhook"
  params: object

Response:
  success: boolean
  result: object

---

# POST /api/v1/channels/{name}/reload
# 重新加载渠道配置
```

---

## 七、实现计划

### 7.1 阶段划分

| 阶段 | 内容 | 工期 | 依赖 |
|------|------|------|------|
| **Phase 1** | Channel Trait 增强 + Base | 1 周 | - |
| **Phase 2** | Channel Manager | 1 周 | Phase 1 |
| **Phase 3** | Webhook Channel | 1 周 | Phase 1, 2 |
| **Phase 4** | 企业微信渠道 | 1 周 | Phase 3 |
| **Phase 5** | 钉钉渠道 | 1 周 | Phase 3 |
| **Phase 6** | 飞书渠道 | 1 周 | Phase 3 |
| **Phase 7** | 插件框架 + SDK | 1 周 | Phase 2 |
| **Phase 8** | 测试 + 文档 | 1 周 | Phase 1-7 |

**总计**: 8 周

---

## 八、测试策略

### 8.1 单元测试

```rust
#[tokio::test]
async fn test_wecom_send_message() {
    let channel = create_test_wecom_channel();
    let result = channel.send("test_user", "Hello").await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_webhook_parse_slack() {
    let parser = SlackParser;
    let payload = load_test_payload("slack_message.json");
    let msg = parser.parse_message(payload).unwrap();
    assert_eq!(msg.sender, "U123456");
    assert_eq!(msg.content, "Test message");
}
```

### 8.2 集成测试

```rust
#[tokio::test]
async fn test_channel_manager_lifecycle() {
    let manager = ChannelManager::test_instance();

    // 注册渠道
    manager.register("test".to_string(), Arc::new(TestChannel)).unwrap();

    // 健康检查
    let health = manager.health_check_all().await;
    assert!(health.iter().any(|h| h.name == "test" && h.status == "healthy"));

    // 注销渠道
    manager.unregister("test").unwrap();
}
```

---

## 九、验收标准

### 9.1 功能验收

- [ ] 企业微信消息收发正常
- [ ] 钉钉消息收发正常
- [ ] 飞书消息收发正常
- [ ] Webhook 渠道可用
- [ ] 插件动态加载正常
- [ ] SDK 可用

### 9.2 质量验收

- [ ] 单元测试覆盖 >80%
- [ ] 集成测试通过
- [ ] 文档完整

---

## 十、参考资源

- [nanobot Channel Manager](../../nanobot/nanobot/channels/)
- [nanoclaw WhatsApp Channel](../../nanoclaw/src/channels/whatsapp.ts)
- [nullclaw Channel VTable](../../nullclaw/src/channels/root.zig)
- [企业微信 API 文档](https://developer.work.weixin.qq.com/document)
- [钉钉开放平台](https://open.dingtalk.com/document)
- [飞书开放平台](https://open.feishu.cn/document)

---

**审批状态**: 待审批  
**负责人**: 待定  
**最后更新**: 2026 年 2 月 27 日
