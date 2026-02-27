# ZeroClaw 优化方案五：浏览器自动化增强

> **版本**: v1.0  
> **创建日期**: 2026 年 2 月 27 日  
> **优先级**: P1 - 重要能力  
> **参考项目**: nanoclaw agent-browser, nullclaw BrowserTool

---

## 一、现状分析

### 1.1 当前 zeroclaw 浏览器支持

```toml
# config.toml - 现有浏览器工具
[tools.browser]
enabled = true
headless = true
timeout_secs = 30
```

| 工具 | 状态 | 说明 |
|------|------|------|
| `browser` | ✅ | 浏览器自动化 |
| `browser_open` | ✅ | 打开网页 |
| `screenshot` | ✅ | 截图 |
| `web_search` | ✅ | 网页搜索 |
| `web_fetch` | ✅ | 网页抓取 |
| `http_request` | ✅ | HTTP 请求 |

### 1.2 存在的问题

| 问题 | 描述 | 企业影响 |
|------|------|---------|
| **无会话管理** | 每次调用新建浏览器 | 效率低，无法保持登录 |
| **无浏览器池** | 无并发控制 | 大规模任务资源耗尽 |
| **沙箱限制** | 容器内运行受限 | 某些网站无法访问 |
| **无录制回放** | 需手写脚本 | 使用门槛高 |
| **缺少视觉 AI** | 无 OCR/图像识别 | 复杂页面交互困难 |
| **无指纹管理** | 浏览器指纹固定 | 易被反爬虫检测 |

### 1.3 对比 nanoclaw 优势

```typescript
// nanoclaw 容器化浏览器
container/
├── Dockerfile
│   # 预装 Chromium + agent-browser
│   RUN apt-get install -y chromium
│   RUN npm install -g agent-browser
└── skills/agent-browser.md
    # 浏览器自动化工具说明
```

**优势**: 容器预装浏览器，环境一致性好

---

## 二、优化目标

### 2.1 核心能力

| 能力 | 目标描述 |
|------|---------|
| **浏览器池** | 预启动浏览器实例池 |
| **会话保持** | 支持 Cookie/LocalStorage 持久化 |
| **远程浏览器** | Playwright 远程服务集成 |
| **录制回放** | 操作录制和脚本生成 |
| **视觉 AI** | OCR + 图像识别 |
| **指纹管理** | 浏览器指纹配置 |
| **反检测** | 反反爬虫措施 |

### 2.2 性能指标

| 指标 | 目标值 |
|------|-------|
| 浏览器启动延迟 | <500ms (池内) |
| 并发浏览器数 | ≥20 |
| 会话恢复时间 | <100ms |
| 截图延迟 | <1s |
| 操作成功率 | >95% |

---

## 三、架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                  Browser Automation System                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           Browser API (统一接口)                          │    │
│  │  - navigate / click / type / screenshot                  │    │
│  │  - session / pool / record / ocr                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Browser Pool (浏览器池)                           │    │
│  │  - 预启动实例                                            │    │
│  │  - 健康检查                                              │    │
│  │  - 资源管理                                              │    │
│  │  - 并发控制                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Session Manager (会话管理)                        │    │
│  │  - Cookie 持久化                                          │    │
│  │  - LocalStorage/SessionStorage                           │    │
│  │  - 会话加密存储                                          │    │
│  │  - 会话同步                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Remote Browser (远程浏览器)                       │    │
│  │  - Playwright 服务                                       │    │
│  │  - Browserless 集成                                      │    │
│  │  - 自定义浏览器服务                                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Visual AI (视觉 AI)                               │    │
│  │  - OCR (Tesseract / 云端)                                │    │
│  │  - 图像识别                                              │    │
│  │  - 元素定位                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Recorder (录制器)                                 │    │
│  │  - 操作捕获                                              │    │
│  │  - 脚本生成                                              │    │
│  │  - 回放执行                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

#### 3.2.1 Browser Pool

```rust
// src/tools/browser/pool.rs

pub struct BrowserPool {
    /// 浏览器实例
    instances: DashMap<String, BrowserInstance>,
    /// 配置
    config: PoolConfig,
    /// 健康检查器
    health_checker: Arc<HealthChecker>,
    /// 资源管理器
    resource_manager: Arc<ResourceManager>,
}

pub struct PoolConfig {
    /// 最小空闲实例
    pub min_idle: usize,
    /// 最大实例数
    pub max_instances: usize,
    /// 实例空闲超时
    pub idle_timeout_secs: u64,
    /// 实例最大寿命
    pub max_lifetime_secs: u64,
    /// 获取超时
    pub acquire_timeout_secs: u64,
    /// 浏览器类型
    pub browser_type: BrowserType,
    /// 无头模式
    pub headless: bool,
}

pub struct BrowserInstance {
    pub id: String,
    pub context: BrowserContext,
    pub page: Page,
    pub created_at: Instant,
    pub last_used: Instant,
    pub usage_count: u32,
    pub status: InstanceStatus,
}

pub enum InstanceStatus {
    Idle,
    Busy,
    Unhealthy,
}

impl BrowserPool {
    /// 获取浏览器实例
    pub async fn acquire(&self) -> Result<PooledBrowser> {
        // 1. 尝试获取空闲实例
        if let Some(instance) = self.get_idle_instance() {
            instance.status = InstanceStatus::Busy;
            return Ok(PooledBrowser {
                instance,
                pool: self.clone(),
            });
        }

        // 2. 创建新实例（如果未达上限）
        if self.instance_count() < self.config.max_instances {
            let instance = self.create_instance().await?;
            return Ok(PooledBrowser {
                instance,
                pool: self.clone(),
            });
        }

        // 3. 等待可用实例
        let instance = self.wait_for_instance().await?;
        Ok(PooledBrowser {
            instance,
            pool: self.clone(),
        })
    }

    /// 归还浏览器实例
    pub fn release(&self, mut instance: BrowserInstance) {
        if self.health_checker.check(&instance).await {
            instance.status = InstanceStatus::Idle;
            instance.last_used = Instant::now();
            self.instances.insert(instance.id.clone(), instance);
        } else {
            // 不健康则销毁
            self.destroy_instance(&instance.id).await;
        }
    }

    /// 预启动浏览器实例
    pub async fn warmup(&self) -> Result<()> {
        while self.idle_count() < self.config.min_idle {
            self.create_instance().await?;
        }
        Ok(())
    }
}
```

#### 3.2.2 Session Manager

```rust
// src/tools/browser/session.rs

pub struct SessionManager {
    /// 会话存储
    sessions: DashMap<String, BrowserSession>,
    /// 加密器
    encryptor: Arc<Encryptor>,
    /// 存储路径
    storage_path: PathBuf,
}

pub struct BrowserSession {
    pub id: String,
    pub user_id: String,
    pub cookies: Vec<Cookie>,
    pub local_storage: HashMap<String, String>,
    pub session_storage: HashMap<String, String>,
    pub created_at: DateTime<Utc>,
    pub last_used: DateTime<Utc>,
    pub expires_at: Option<DateTime<Utc>>,
}

pub struct SessionConfig {
    /// 会话持久化
    pub persist: bool,
    /// 会话加密
    pub encrypt: bool,
    /// 会话过期时间
    pub ttl_hours: u64,
    /// 自动刷新
    pub auto_refresh: bool,
}

impl SessionManager {
    /// 创建新会话
    pub fn create_session(&self, user_id: &str) -> Result<String> {
        let session_id = generate_session_id();
        let session = BrowserSession {
            id: session_id.clone(),
            user_id: user_id.to_string(),
            cookies: Vec::new(),
            local_storage: HashMap::new(),
            session_storage: HashMap::new(),
            created_at: Utc::now(),
            last_used: Utc::now(),
            expires_at: None,
        };

        self.sessions.insert(session_id.clone(), session);
        Ok(session_id)
    }

    /// 保存会话（从浏览器上下文）
    pub async fn save_from_context(&self, session_id: &str, context: &BrowserContext) -> Result<()> {
        let cookies = context.cookies().await?;
        let local_storage = context.local_storage().await?;

        let mut session = self.sessions.get_mut(session_id)
            .ok_or_else(|| anyhow!("Session not found"))?;

        session.cookies = cookies;
        session.local_storage = local_storage;
        session.last_used = Utc::now();

        // 持久化到磁盘
        if self.config.persist {
            self.persist_to_disk(&session).await?;
        }

        Ok(())
    }

    /// 恢复会话（到浏览器上下文）
    pub async fn restore_to_context(&self, session_id: &str, context: &BrowserContext) -> Result<()> {
        let session = self.sessions.get(session_id)
            .ok_or_else(|| anyhow!("Session not found"))?;

        // 恢复 Cookies
        for cookie in &session.cookies {
            context.add_cookie(cookie).await?;
        }

        // 恢复 LocalStorage
        for (key, value) in &session.local_storage {
            context.set_local_storage(key, value).await?;
        }

        Ok(())
    }

    /// 持久化到磁盘（加密）
    async fn persist_to_disk(&self, session: &BrowserSession) -> Result<()> {
        let path = self.storage_path.join(format!("{}.session", session.id));

        let data = serde_json::to_vec(session)?;

        let encrypted = if self.config.encrypt {
            self.encryptor.encrypt(&data)?
        } else {
            data
        };

        tokio::fs::write(path, encrypted).await?;
        Ok(())
    }

    /// 从磁盘加载
    pub async fn load_from_disk(&self, session_id: &str) -> Result<BrowserSession> {
        let path = self.storage_path.join(format!("{}.session", session_id));

        let encrypted = tokio::fs::read(path).await?;

        let data = if self.config.encrypt {
            self.encryptor.decrypt(&encrypted)?
        } else {
            encrypted
        };

        let session: BrowserSession = serde_json::from_slice(&data)?;
        Ok(session)
    }
}
```

#### 3.2.3 Remote Browser

```rust
// src/tools/browser/remote.rs

pub struct RemoteBrowserProvider {
    /// 服务端点
    endpoint: String,
    /// 认证
    auth: Option<AuthConfig>,
    /// HTTP 客户端
    client: reqwest::Client,
}

pub struct AuthConfig {
    pub api_key: String,
    pub api_key_header: String,
}

impl RemoteBrowserProvider {
    /// 创建 Playwright 远程连接
    pub fn new_playwright(endpoint: String, auth: Option<AuthConfig>) -> Result<Self> {
        Ok(Self {
            endpoint,
            auth,
            client: reqwest::Client::new(),
        })
    }

    /// 创建 Browserless 连接
    pub fn new_browserless(token: String) -> Result<Self> {
        Ok(Self {
            endpoint: "wss://chrome.browserless.io".to_string(),
            auth: Some(AuthConfig {
                api_key: token,
                api_key_header: "Authorization".to_string(),
            }),
            client: reqwest::Client::new(),
        })
    }

    /// 导航到 URL
    pub async fn navigate(&self, session_id: &str, url: &str) -> Result<()> {
        let payload = json!({
            "sessionId": session_id,
            "action": "navigate",
            "params": { "url": url }
        });

        let resp = self.client
            .post(&self.endpoint)
            .json(&payload)
            .send()
            .await?;

        if !resp.status().is_success() {
            return Err(anyhow!("Remote browser error: {}", resp.text().await?));
        }

        Ok(())
    }

    /// 截图
    pub async fn screenshot(&self, session_id: &str) -> Result<Vec<u8>> {
        let payload = json!({
            "sessionId": session_id,
            "action": "screenshot",
            "params": { "format": "png" }
        });

        let resp = self.client
            .post(&self.endpoint)
            .json(&payload)
            .send()
            .await?;

        Ok(resp.bytes().await?.to_vec())
    }

    /// 执行 JavaScript
    pub async fn evaluate(&self, session_id: &str, script: &str) -> Result<Value> {
        let payload = json!({
            "sessionId": session_id,
            "action": "evaluate",
            "params": { "function": script }
        });

        let resp = self.client
            .post(&self.endpoint)
            .json(&payload)
            .send()
            .await?;

        Ok(resp.json().await?)
    }
}
```

#### 3.2.4 Visual AI

```rust
// src/tools/browser/visual.rs

pub struct VisualAI {
    /// OCR 引擎
    ocr: Arc<dyn OcrEngine>,
    /// 图像识别
    vision: Arc<dyn VisionModel>,
}

pub trait OcrEngine: Send + Sync {
    fn recognize(&self, image: &[u8]) -> Result<OcrResult>;
    fn recognize_with_lang(&self, image: &[u8], lang: &str) -> Result<OcrResult>;
}

pub struct TesseractOcr {
    api: tesseract::Tesseract,
}

impl OcrEngine for TesseractOcr {
    fn recognize(&self, image: &[u8]) -> Result<OcrResult> {
        let text = self.api.run(image, "eng")?;
        Ok(OcrResult { text, confidence: 0.0 })
    }

    fn recognize_with_lang(&self, image: &[u8], lang: &str) -> Result<OcrResult> {
        let text = self.api.run(image, lang)?;
        Ok(OcrResult { text, confidence: 0.0 })
    }
}

pub struct CloudOcr {
    client: reqwest::Client,
    api_key: String,
    endpoint: String,
}

// Google Cloud Vision
pub struct GoogleVisionOcr {
    client: reqwest::Client,
    api_key: String,
}

impl OcrEngine for GoogleVisionOcr {
    fn recognize(&self, image: &[u8]) -> Result<OcrResult> {
        // 调用 Google Cloud Vision API
        // ...
    }
}

pub trait VisionModel: Send + Sync {
    /// 图像描述
    fn describe(&self, image: &[u8]) -> Result<String>;
    /// 元素定位
    fn locate_elements(&self, image: &[u8], description: &str) -> Result<Vec<Rect>>;
    /// 图像问答
    fn answer_question(&self, image: &[u8], question: &str) -> Result<String>;
}

pub struct LlavaVision {
    model_path: PathBuf,
    // 本地 LLaVA 模型
}

pub struct ClaudeVision {
    client: reqwest::Client,
    api_key: String,
}

impl VisualAI {
    /// OCR 识别
    pub fn ocr(&self, screenshot: &[u8], lang: Option<&str>) -> Result<String> {
        let result = if let Some(lang) = lang {
            self.ocr.recognize_with_lang(screenshot, lang)?
        } else {
            self.ocr.recognize(screenshot)?
        };
        Ok(result.text)
    }

    /// 查找按钮
    pub fn find_button(&self, screenshot: &[u8], text: &str) -> Result<Option<Rect>> {
        let description = format!("Find button with text '{}'", text);
        let rects = self.vision.locate_elements(screenshot, &description)?;
        Ok(rects.into_iter().next())
    }

    /// 智能点击
    pub async fn smart_click(&self, page: &Page, target: &str) -> Result<()> {
        // 1. 截图
        let screenshot = page.screenshot().await?;

        // 2. 使用视觉 AI 定位
        let rect = self.vision
            .locate_elements(&screenshot, &format!("Click on {}", target))?
            .into_iter()
            .next()
            .ok_or_else(|| anyhow!("Element not found: {}", target))?;

        // 3. 计算坐标并点击
        let x = rect.x + rect.width / 2;
        let y = rect.y + rect.height / 2;
        page.mouse().click(x as f64, y as f64).await?;

        Ok(())
    }
}
```

#### 3.2.5 Recorder

```rust
// src/tools/browser/recorder.rs

pub struct BrowserRecorder {
    /// 事件捕获
    capturer: Arc<EventCapturer>,
    /// 脚本生成器
    generator: Arc<ScriptGenerator>,
    /// 回放器
    player: Arc<ScriptPlayer>,
}

pub struct RecordedEvent {
    pub timestamp: Instant,
    pub event_type: EventType,
    pub target: ElementInfo,
    pub action: Action,
    pub screenshot: Option<Vec<u8>>,
}

pub enum EventType {
    Click,
    DoubleClick,
    RightClick,
    Type,
    Navigate,
    Scroll,
    Select,
    Hover,
}

pub struct ElementInfo {
    pub selector: String,
    pub xpath: String,
    pub tag_name: String,
    pub attributes: HashMap<String, String>,
    pub text: Option<String>,
    pub screenshot: Option<Vec<u8>>,
}

pub struct BrowserScript {
    pub name: String,
    pub description: String,
    pub steps: Vec<ScriptStep>,
    pub variables: HashMap<String, Value>,
}

pub struct ScriptStep {
    pub action: String,
    pub target: Option<String>,
    pub params: HashMap<String, Value>,
    pub timeout_secs: u64,
    pub retry_count: u32,
}

impl BrowserRecorder {
    /// 开始录制
    pub fn start_recording(&self) -> Result<RecordingSession> {
        let session = RecordingSession::new();
        self.capturer.start(session.clone())?;
        Ok(session)
    }

    /// 停止录制
    pub fn stop_recording(&self, session: &RecordingSession) -> Result<BrowserScript> {
        self.capturer.stop()?;

        let events = session.get_events();
        let script = self.generator.generate(events)?;

        Ok(script)
    }

    /// 回放脚本
    pub async fn play(&self, script: &BrowserScript, context: &BrowserContext) -> Result<PlayResult> {
        self.player.execute(script, context).await
    }

    /// 保存脚本
    pub fn save_script(&self, script: &BrowserScript, path: &Path) -> Result<()> {
        let content = serde_yaml::to_string(script)?;
        std::fs::write(path, content)?;
        Ok(())
    }

    /// 加载脚本
    pub fn load_script(&self, path: &Path) -> Result<BrowserScript> {
        let content = std::fs::read_to_string(path)?;
        let script: BrowserScript = serde_yaml::from_str(&content)?;
        Ok(script)
    }
}
```

---

## 四、配置设计

### 4.1 浏览器配置

```toml
# config.toml

[tools.browser]
enabled = true

# 浏览器池配置
[tools.browser.pool]
min_idle = 2
max_instances = 20
idle_timeout_secs = 300
max_lifetime_secs = 3600
acquire_timeout_secs = 30

# 浏览器类型：chromium | firefox | webkit
browser_type = "chromium"
headless = true

# 反检测
[tools.browser.anti_detect]
enabled = true
# 用户代理轮换
rotate_user_agent = true
# 指纹配置
[tools.browser.fingerprint]
screen_width = 1920
screen_height = 1080
timezone = "Asia/Shanghai"
locale = "zh-CN"

# 会话管理
[tools.browser.session]
persist = true
encrypt = true
ttl_hours = 168  # 7 天
auto_refresh = true
storage_path = "~/.zeroclaw/browser/sessions"

# 远程浏览器
[tools.browser.remote]
enabled = false
# 服务类型：playwright | browserless | custom
service_type = "playwright"
endpoint = "ws://localhost:3000"
api_key = "${BROWSER_API_KEY}"

# 视觉 AI
[tools.browser.visual]
enabled = true
# OCR 引擎：tesseract | google | azure
ocr_engine = "tesseract"
ocr_languages = ["eng", "chi_sim"]
# 视觉模型：llava | claude | gpt4v
vision_model = "claude"
vision_api_key = "${ANTHROPIC_API_KEY}"

# 录制器
[tools.browser.recorder]
enabled = true
output_dir = "~/.zeroclaw/browser/scripts"
auto_save = true
include_screenshots = true
```

---

## 五、工具设计

### 5.1 新增工具

```rust
// src/tools/browser_actions.rs

/// 浏览器操作工具集
pub struct BrowserActionsTool {
    pool: Arc<BrowserPool>,
    session_manager: Arc<SessionManager>,
    visual_ai: Arc<VisualAI>,
}

#[derive(Serialize, Deserialize)]
pub struct BrowserActions {
    /// 打开网页
    pub navigate: NavigateParams,
    /// 点击元素
    pub click: ClickParams,
    /// 输入文本
    pub type_text: TypeTextParams,
    /// 截图
    pub screenshot: ScreenshotParams,
    /// 获取内容
    pub get_content: GetContentParams,
    /// 执行 JS
    pub evaluate: EvaluateParams,
    /// 等待元素
    pub wait_for: WaitForParams,
    /// 智能点击（视觉 AI）
    pub smart_click: SmartClickParams,
    /// OCR 识别
    pub ocr: OcrParams,
    /// 加载会话
    pub load_session: LoadSessionParams,
    /// 保存会话
    pub save_session: SaveSessionParams,
}

impl Tool for BrowserActionsTool {
    fn name(&self) -> &str { "browser_actions" }

    fn description(&self) -> &str {
        "Browser automation with session management and visual AI capabilities"
    }

    async fn execute(&self, args: serde_json::Value) -> Result<ToolResult> {
        let action: BrowserAction = serde_json::from_value(args)?;

        let browser = self.pool.acquire().await?;

        match action {
            BrowserAction::Navigate(params) => {
                browser.page.goto(&params.url).await?;
                Ok(ToolResult::success(format!("Navigated to {}", params.url)))
            }
            BrowserAction::SmartClick(params) => {
                let screenshot = browser.page.screenshot().await?;
                let rect = self.visual_ai
                    .find_button(&screenshot, &params.target)?
                    .ok_or_else(|| anyhow!("Element not found"))?;
                // 点击...
                Ok(ToolResult::success("Clicked"))
            }
            BrowserAction::Ocr(params) => {
                let screenshot = browser.page.screenshot().await?;
                let text = self.visual_ai.ocr(&screenshot, params.lang.as_deref())?;
                Ok(ToolResult::success(text))
            }
            // ... 其他动作
        }
    }
}
```

### 5.2 脚本格式

```yaml
# ~/.zeroclaw/browser/scripts/login_github.yaml

name: github_login
description: 登录 GitHub

variables:
  username: "${GITHUB_USERNAME}"
  password: "${GITHUB_PASSWORD}"

steps:
  - action: navigate
    params:
      url: https://github.com/login
    timeout_secs: 30

  - action: type_text
    target: "#login_field"
    params:
      text: "{{username}}"
    timeout_secs: 10

  - action: type_text
    target: "#password"
    params:
      text: "{{password}}"
    timeout_secs: 10

  - action: click
    target: "input[type='submit']"
    timeout_secs: 10

  - action: wait_for
    params:
      selector: ".dashboard-sidebar"
    timeout_secs: 30

  - action: screenshot
    params:
      path: "~/screenshots/github_logged_in.png"
```

---

## 六、实现计划

### 6.1 阶段划分

| 阶段 | 内容 | 工期 | 依赖 |
|------|------|------|------|
| **Phase 1** | Browser Pool | 1 周 | - |
| **Phase 2** | Session Manager | 1 周 | Phase 1 |
| **Phase 3** | Remote Browser | 1 周 | - |
| **Phase 4** | Visual AI (OCR) | 1 周 | - |
| **Phase 5** | Visual AI (Vision) | 1 周 | Phase 4 |
| **Phase 6** | Recorder | 1 周 | Phase 1 |
| **Phase 7** | 工具集成 + CLI | 1 周 | Phase 1-6 |
| **Phase 8** | 测试 + 文档 | 1 周 | Phase 1-7 |

**总计**: 8 周

---

## 七、验收标准

### 7.1 功能验收

- [ ] 浏览器池正常工作
- [ ] 会话持久化/恢复正常
- [ ] 远程浏览器连接正常
- [ ] OCR 识别准确
- [ ] 视觉 AI 定位准确
- [ ] 录制回放正常

### 7.2 性能验收

- [ ] 浏览器获取延迟 <500ms
- [ ] 支持≥20 并发浏览器
- [ ] 会话恢复 <100ms
- [ ] 截图延迟 <1s

---

## 八、参考资源

- [nanoclaw 容器浏览器](../../nanoclaw/container/Dockerfile)
- [Playwright 文档](https://playwright.dev)
- [Browserless 文档](https://www.browserless.io)
- [Tesseract OCR](https://tesseract-ocr.github.io)

---

**审批状态**: 待审批  
**负责人**: 待定  
**最后更新**: 2026 年 2 月 27 日
