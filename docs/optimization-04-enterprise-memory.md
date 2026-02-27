# ZeroClaw 优化方案四：企业级记忆系统

> **版本**: v1.0  
> **创建日期**: 2026 年 2 月 27 日  
> **优先级**: P1 - 重要能力  
> **参考项目**: nullclaw 分层记忆架构，zeroclaw 现有记忆系统

---

## 一、现状分析

### 1.1 当前 zeroclaw 记忆系统

```toml
# config.toml - 现有记忆配置
[memory]
backend = "sqlite"             # sqlite | lucid | postgres | markdown | none
auto_save = true
embedding_provider = "none"
vector_weight = 0.7
keyword_weight = 0.3
```

### 1.2 现有架构

```
memory/
├── engines/          # 存储后端
│   ├── sqlite.rs     # SQLite + FTS5
│   ├── postgres.rs   # PostgreSQL
│   └── markdown.rs   # Markdown 文件
├── retrieval/        # 检索引擎
│   ├── engine.rs     # 检索接口
│   ├── rrf.rs        # RRF 合并
│   └── hybrid.rs     # 混合搜索
├── vector/           # 向量搜索
│   ├── embeddings.rs # 嵌入生成
│   └── store.rs      # 向量存储
└── lifecycle/        # 生命周期
    ├── cache.rs      # 缓存
    └── hygiene.rs    # 清理
```

### 1.3 存在的问题

| 问题 | 描述 | 企业影响 |
|------|------|---------|
| **跨 Agent 共享弱** | 记忆隔离为主 | 团队协作困难 |
| **权限控制粗** | 无细粒度访问控制 | 数据泄露风险 |
| **外部向量库缺失** | 仅 SQLite 向量 | 大规模检索性能差 |
| **记忆类别单一** | 基础分类 | 知识管理困难 |
| **无版本控制** | 记忆更新无追溯 | 审计困难 |
| **缺少知识图谱** | 纯文本存储 | 关联查询能力弱 |

### 1.4 对比 nullclaw 优势

```zig
// nullclaw 分层记忆架构
memory/
├── engines/          # Layer A: 主存储后端
│   ├── sqlite.zig    # SQLite + FTS5
│   ├── redis.zig     # Redis
│   └── lancedb.zig   # LanceDB 向量
├── retrieval/        # Layer B: 检索引擎
│   ├── rrf.zig       # RRF 合并
│   └── engine.zig    # 检索接口
├── vector/           # Layer C: 向量平面
│   ├── embeddings.zig # 嵌入生成
│   └── math.zig      # 余弦相似度
└── lifecycle/        # Layer D: 运行时编排
    ├── cache.zig     # 响应缓存
    └── snapshot.zig  # 快照导出
```

**优势**: 分层清晰，零外部依赖，混合搜索完善

---

## 二、优化目标

### 2.1 核心能力

| 能力 | 目标描述 |
|------|---------|
| **共享记忆池** | 跨 Agent/租户共享记忆 |
| **细粒度权限** | 记忆级访问控制 |
| **外部向量库** | Milvus/Weaviate/Pinecone 集成 |
| **知识图谱** | 实体关系存储和查询 |
| **版本控制** | 记忆变更追溯 |
| **智能分块** | 语义分块 + 重叠策略 |
| **多租户隔离** | 租户记忆完全隔离 |

### 2.2 性能指标

| 指标 | 目标值 |
|------|-------|
| 检索延迟 (P99) | <100ms |
| 向量搜索 QPS | >1000 |
| 记忆条目容量 | >1000 万 |
| 嵌入生成速度 | >100/s |
| 压缩率 | >50% |

---

## 三、架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Enterprise Memory System                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           Memory API (统一接口)                           │    │
│  │  - save / get / search / delete                          │    │
│  │  - share / revoke / version / graph                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Memory Router (路由层)                            │    │
│  │  - 租户路由                                              │    │
│  │  - 权限检查                                              │    │
│  │  - 缓存路由                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Storage Layer (存储层)                            │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │   SQLite    │  │  PostgreSQL │  │   Redis     │      │    │
│  │  │  (FTS5+Vec) │  │  (pgvector) │  │  (Cache)    │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │   Milvus    │  │  Weaviate   │  │  Pinecone   │      │    │
│  │  │  (向量库)   │  │  (向量库)   │  │  (向量云)   │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Knowledge Graph (知识图谱)                        │    │
│  │  - 实体提取                                              │    │
│  │  - 关系存储                                              │    │
│  │  - 图查询                                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Processing Layer (处理层)                         │    │
│  │  - 智能分块                                              │    │
│  │  - 嵌入生成                                              │    │
│  │  - 实体抽取                                              │    │
│  │  - 自动摘要                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

#### 3.2.1 Memory Trait 增强

```rust
// src/memory/mod.rs

#[async_trait]
pub trait Memory: Send + Sync {
    // ========== 基础操作 ==========

    /// 保存记忆
    async fn save(&self, key: &str, value: &str, category: MemoryCategory) -> Result<()>;

    /// 获取记忆
    async fn get(&self, key: &str) -> Result<Option<MemoryEntry>>;

    /// 搜索记忆
    async fn search(&self, query: &str, limit: usize) -> Result<Vec<MemoryEntry>>;

    /// 删除记忆
    async fn delete(&self, key: &str) -> Result<bool>;

    // ========== 企业级功能 ==========

    /// 保存记忆（带元数据和权限）
    async fn save_with_metadata(
        &self,
        key: &str,
        value: &str,
        metadata: MemoryMetadata,
    ) -> Result<()> {
        // 默认实现：调用基础 save
        self.save(key, value, metadata.category).await
    }

    /// 共享记忆
    async fn share(&self, key: &str, with_tenant: &str, access: AccessLevel) -> Result<()>;

    /// 撤销共享
    async fn revoke_share(&self, key: &str, with_tenant: &str) -> Result<()>;

    /// 获取记忆版本历史
    async fn get_versions(&self, key: &str) -> Result<Vec<MemoryVersion>>;

    /// 恢复到指定版本
    async fn restore_version(&self, key: &str, version: u64) -> Result<()>;

    /// 图谱查询
    async fn graph_query(&self, query: GraphQuery) -> Result<Vec<GraphResult>>;

    /// 批量导入
    async fn batch_import(&self, entries: Vec<MemoryEntry>) -> Result<ImportResult>;

    /// 批量导出
    async fn batch_export(&self, filter: MemoryFilter) -> Result<Vec<MemoryEntry>>;

    /// 记忆统计
    async fn stats(&self) -> Result<MemoryStats>;
}

pub struct MemoryMetadata {
    /// 类别
    pub category: MemoryCategory,
    /// 租户 ID
    pub tenant_id: String,
    /// 创建者
    pub created_by: String,
    /// 访问权限
    pub access_policy: AccessPolicy,
    /// 标签
    pub tags: Vec<String>,
    /// 过期时间
    pub expires_at: Option<DateTime<Utc>>,
    /// 自定义元数据
    pub custom: HashMap<String, Value>,
}

pub enum AccessLevel {
    Read,
    Write,
    Admin,
}
```

#### 3.2.2 Memory Router

```rust
// src/memory/router.rs

pub struct MemoryRouter {
    /// 租户记忆存储
    tenant_stores: DashMap<String, Arc<dyn MemoryBackend>>,
    /// 共享记忆池
    shared_pool: Arc<SharedMemoryPool>,
    /// 权限检查器
    acl: Arc<MemoryACL>,
    /// 缓存层
    cache: Arc<MemoryCache>,
}

pub struct SharedMemoryPool {
    /// 共享记忆存储
    store: Arc<dyn MemoryBackend>,
    /// 共享关系
    shares: DashMap<String, Vec<ShareRelation>>,
}

pub struct ShareRelation {
    pub memory_key: String,
    pub owner_tenant: String,
    pub shared_with: String,
    pub access_level: AccessLevel,
    pub shared_at: DateTime<Utc>,
}

impl MemoryRouter {
    /// 保存记忆（自动路由到租户存储）
    pub async fn save(&self, tenant_id: &str, key: &str, value: &str, metadata: MemoryMetadata) -> Result<()> {
        // 1. 权限检查
        self.acl.check_write(tenant_id, key, &metadata.created_by)?;

        // 2. 获取租户存储
        let store = self.get_tenant_store(tenant_id);

        // 3. 保存
        store.save(key, value, metadata).await?;

        // 4. 更新缓存
        self.cache.invalidate(key);

        Ok(())
    }

    /// 搜索记忆（跨租户存储 + 共享池）
    pub async fn search(&self, tenant_id: &str, query: &str, limit: usize) -> Result<Vec<MemoryEntry>> {
        // 1. 搜索租户记忆
        let tenant_results = self.get_tenant_store(tenant_id)
            .search(query, limit)
            .await?;

        // 2. 搜索共享记忆
        let shared_results = self.shared_pool
            .search_shared(tenant_id, query, limit - tenant_results.len())
            .await?;

        // 3. 合并结果（RRF）
        let merged = reciprocal_rank_fusion(tenant_results, shared_results);

        // 4. 权限过滤
        let filtered = self.acl.filter_readable(tenant_id, merged);

        Ok(filtered)
    }

    /// 获取租户存储（不存在则创建）
    fn get_tenant_store(&self, tenant_id: &str) -> Arc<dyn MemoryBackend> {
        self.tenant_stores
            .entry(tenant_id.to_string())
            .or_insert_with(|| {
                self.create_tenant_store(tenant_id)
            })
            .clone()
    }
}
```

#### 3.2.3 外部向量库集成

```rust
// src/memory/vector/external.rs

/// 向量库 Trait
#[async_trait]
pub trait VectorStore: Send + Sync {
    /// 添加向量
    async fn insert(&self, id: &str, vector: Vec<f32>, metadata: Value) -> Result<()>;

    /// 向量搜索
    async fn search(&self, query: Vec<f32>, limit: usize, filter: Option<Value>) -> Result<Vec<VectorResult>>;

    /// 删除向量
    async fn delete(&self, id: &str) -> Result<()>;

    /// 批量操作
    async fn batch_insert(&self, vectors: Vec<VectorInput>) -> Result<()>;

    /// 统计
    async fn stats(&self) -> Result<VectorStats>;
}

/// Milvus 实现
pub struct MilvusVectorStore {
    client: milvus_client::Client,
    collection: String,
    index_params: IndexParams,
}

impl MilvusVectorStore {
    pub async fn new(config: MilvusConfig) -> Result<Self> {
        let client = milvus_client::Client::new(&config.host).await?;

        // 创建集合
        client.create_collection(&config.collection, &config.schema).await?;

        // 创建索引
        client.create_index(&config.collection, &config.index_params).await?;

        Ok(Self {
            client,
            collection: config.collection,
            index_params: config.index_params,
        })
    }
}

#[async_trait]
impl VectorStore for MilvusVectorStore {
    async fn insert(&self, id: &str, vector: Vec<f32>, metadata: Value) -> Result<()> {
        let entities = vec![
            FieldValue::id(id),
            FieldValue::vector(&vector),
            FieldValue::json(&metadata),
        ];

        self.client.insert(&self.collection, entities).await?;
        Ok(())
    }

    async fn search(&self, query: Vec<f32>, limit: usize, filter: Option<Value>) -> Result<Vec<VectorResult>> {
        let results = self.client
            .search(
                &self.collection,
                &query,
                limit,
                self.index_params.metric_type,
                filter.map(|f| f.to_string()),
            )
            .await?;

        Ok(results.into_iter()
            .map(|r| VectorResult {
                id: r.id,
                score: r.score,
                metadata: r.metadata,
            })
            .collect())
    }
}

/// Weaviate 实现
pub struct WeaviateVectorStore {
    client: weaviate_client::Client,
    class_name: String,
}

/// Pinecone 实现
pub struct PineconeVectorStore {
    client: pinecone_client::Client,
    index_name: String,
}
```

#### 3.2.4 知识图谱

```rust
// src/memory/graph.rs

pub struct KnowledgeGraph {
    /// 图存储
    store: Arc<dyn GraphStore>,
    /// 实体提取器
    extractor: Arc<EntityExtractor>,
}

pub struct Entity {
    pub id: String,
    pub name: String,
    pub entity_type: EntityType,
    pub properties: HashMap<String, Value>,
    pub embeddings: Option<Vec<f32>>,
}

pub enum EntityType {
    Person,
    Organization,
    Location,
    Event,
    Concept,
    Document,
    Custom(String),
}

pub struct Relation {
    pub id: String,
    pub from_entity: String,
    pub to_entity: String,
    pub relation_type: String,
    pub properties: HashMap<String, Value>,
}

pub struct GraphQuery {
    /// 查询类型
    pub query_type: GraphQueryType,
    /// 起始实体
    pub start_entity: Option<String>,
    /// 关系类型过滤
    pub relation_filter: Option<Vec<String>>,
    /// 最大深度
    pub max_depth: u32,
    /// 自定义查询
    pub custom_query: Option<String>,
}

pub enum GraphQueryType {
    /// 邻居查询
    Neighbors,
    /// 路径查询
    Path { target: String },
    /// 子图查询
    Subgraph,
    /// 模式匹配
    Pattern(String),
}

impl KnowledgeGraph {
    /// 从文本提取实体和关系
    pub async fn extract_from_text(&self, text: &str, memory_key: &str) -> Result<ExtractionResult> {
        let entities = self.extractor.extract_entities(text).await?;
        let relations = self.extractor.extract_relations(text, &entities).await?;

        // 存储到图
        for entity in &entities {
            self.store.add_entity(entity).await?;
        }
        for relation in &relations {
            self.store.add_relation(relation).await?;
        }

        // 关联到记忆
        for entity in &entities {
            self.store.link_to_memory(&entity.id, memory_key).await?;
        }

        Ok(ExtractionResult { entities, relations })
    }

    /// 图谱查询
    pub async fn query(&self, query: GraphQuery) -> Result<Vec<GraphResult>> {
        match query.query_type {
            GraphQueryType::Neighbors => {
                self.store.get_neighbors(
                    query.start_entity.as_ref().unwrap(),
                    query.relation_filter,
                    query.max_depth,
                ).await
            }
            GraphQueryType::Path { target } => {
                self.store.find_path(
                    query.start_entity.as_ref().unwrap(),
                    &target,
                    query.max_depth,
                ).await
            }
            // ...
        }
    }

    /// 图谱增强搜索
    pub async fn search_with_graph(&self, text_query: &str, graph_query: GraphQuery) -> Result<Vec<MemoryEntry>> {
        // 1. 文本搜索
        let text_results = self.memory.search(text_query, 50).await?;

        // 2. 图谱查询
        let graph_results = self.query(graph_query).await?;

        // 3. 提取图谱相关的记忆
        let graph_memory_keys: Vec<_> = graph_results
            .iter()
            .flat_map(|r| r.linked_memories())
            .collect();

        let graph_memories = self.memory.batch_get(&graph_memory_keys).await?;

        // 4. 合并结果
        let merged = reciprocal_rank_fusion(text_results, graph_memories);

        Ok(merged)
    }
}
```

#### 3.2.5 智能分块

```rust
// src/memory/chunking.rs

pub struct ChunkingStrategy {
    /// 分块方法
    method: ChunkMethod,
    /// 块大小（tokens）
    chunk_size: usize,
    /// 重叠大小（tokens）
    overlap_size: usize,
    /// 语义分块配置
    semantic_config: Option<SemanticConfig>,
}

pub enum ChunkMethod {
    /// 固定大小
    Fixed,
    /// 按段落
    Paragraph,
    /// 按句子
    Sentence,
    /// 语义分块
    Semantic,
    /// 递归分块
    Recursive,
}

pub struct SemanticConfig {
    /// 嵌入模型
    embedding_model: String,
    /// 相似度阈值
    similarity_threshold: f32,
    /// 最小块大小
    min_chunk_size: usize,
    /// 最大块大小
    max_chunk_size: usize,
}

impl ChunkingStrategy {
    /// 分块
    pub fn chunk(&self, text: &str) -> Vec<Chunk> {
        match self.method {
            ChunkMethod::Fixed => self.chunk_fixed(text),
            ChunkMethod::Paragraph => self.chunk_paragraph(text),
            ChunkMethod::Semantic => self.chunk_semantic(text),
            ChunkMethod::Recursive => self.chunk_recursive(text),
        }
    }

    /// 语义分块实现
    fn chunk_semantic(&self, text: &str) -> Vec<Chunk> {
        // 1. 按句子分割
        let sentences = self.split_sentences(text);

        // 2. 计算句子嵌入
        let embeddings = self.compute_embeddings(&sentences);

        // 3. 基于相似度聚类
        let clusters = self.cluster_by_similarity(&embeddings, self.semantic_config.similarity_threshold);

        // 4. 合并簇为块
        let mut chunks = Vec::new();
        for cluster in clusters {
            let chunk_text: String = cluster
                .iter()
                .map(|&i| sentences[i])
                .collect::<Vec<_>>()
                .join(" ");

            if chunk_text.len() >= self.semantic_config.min_chunk_size {
                chunks.push(Chunk {
                    content: chunk_text,
                    metadata: ChunkMetadata {
                        sentence_count: cluster.len(),
                        ..Default::default()
                    },
                });
            }
        }

        chunks
    }
}
```

---

## 四、配置设计

### 4.1 记忆配置

```toml
# config.toml

[memory]
# 主后端
backend = "sqlite"

# 租户隔离
[memory.tenant_isolation]
enabled = true
per_tenant_database = true

# 共享记忆池
[memory.shared_pool]
enabled = true
backend = "postgres"
connection_string = "postgresql://user:pass@localhost/memory_pool"

# 向量搜索
[memory.vector]
# 向量后端：sqlite | milvus | weaviate | pinecone
backend = "milvus"

[memory.vector.milvus]
host = "http://localhost:19530"
collection = "zeroclaw_memories"
dimension = 1536
metric_type = "COSINE"
index_type = "HNSW"

[memory.vector.embeddings]
# 嵌入 Provider
provider = "openai"
model = "text-embedding-3-small"
# 或者本地模型
# provider = "local"
# model_path = "~/.zeroclaw/models/bge-large-zh"

# 混合搜索权重
[memory.search]
vector_weight = 0.7
keyword_weight = 0.3
reciprocal_rank_fusion = true

# 知识图谱
[memory.graph]
enabled = true
backend = "neo4j"

[memory.graph.neo4j]
uri = "neo4j://localhost:7687"
user = "neo4j"
password = "${NEO4J_PASSWORD}"

# 实体提取
[memory.graph.extraction]
enabled = true
# 提取模型
model = "anthropic/claude-sonnet-4-6"
# 自动提取触发条件
auto_extract = true
min_text_length = 100

# 智能分块
[memory.chunking]
method = "semantic"
chunk_size = 512
overlap_size = 50

[memory.chunking.semantic]
similarity_threshold = 0.7
min_chunk_size = 100
max_chunk_size = 1024

# 缓存
[memory.cache]
enabled = true
backend = "redis"
connection_string = "redis://localhost:6379"
ttl_seconds = 3600
max_entries = 10000

# 版本控制
[memory.versioning]
enabled = true
max_versions = 10
```

---

## 五、API 设计

### 5.1 CLI 命令

```bash
# 记忆管理
zeroclaw memory save <key> <value> [--category <category>] [--tags <tags>]
zeroclaw memory get <key>
zeroclaw memory search <query> [--limit <limit>]
zeroclaw memory delete <key>

# 版本控制
zeroclaw memory versions <key>
zeroclaw memory restore <key> --version <version>

# 共享
zeroclaw memory share <key> --with <tenant> --access <access>
zeroclaw memory revoke <key> --with <tenant>

# 知识图谱
zeroclaw memory graph query <entity> [--depth <depth>]
zeroclaw memory graph entities [--type <type>]
zeroclaw memory graph relations <entity>

# 统计
zeroclaw memory stats
zeroclaw memory export --output <file> [--format json|markdown]

# 向量库管理
zeroclaw memory vector rebuild [--collection <collection>]
zeroclaw memory vector stats
```

---

## 六、实现计划

### 6.1 阶段划分

| 阶段 | 内容 | 工期 | 依赖 |
|------|------|------|------|
| **Phase 1** | Memory Router + 租户隔离 | 2 周 | - |
| **Phase 2** | 共享记忆池 | 1 周 | Phase 1 |
| **Phase 3** | Milvus 集成 | 1 周 | - |
| **Phase 4** | Weaviate/Pinecone 集成 | 1 周 | Phase 3 |
| **Phase 5** | 知识图谱 (Neo4j) | 2 周 | - |
| **Phase 6** | 智能分块 | 1 周 | - |
| **Phase 7** | 版本控制 | 1 周 | - |
| **Phase 8** | CLI + 测试 | 1 周 | Phase 1-7 |

**总计**: 10 周

---

## 七、验收标准

### 7.1 功能验收

- [ ] 租户记忆隔离正常
- [ ] 共享记忆池可用
- [ ] 外部向量库集成正常
- [ ] 知识图谱查询可用
- [ ] 版本控制正常
- [ ] 智能分块生效

### 7.2 性能验收

- [ ] 检索延迟 <100ms (P99)
- [ ] 向量搜索 QPS >1000
- [ ] 支持>1000 万记忆条目

---

## 八、参考资源

- [nullclaw 记忆系统](../../nullclaw/src/memory/)
- [zeroclaw 现有记忆](src/memory/)
- [Milvus 文档](https://milvus.io/docs)
- [Neo4j 文档](https://neo4j.com/docs)

---

**审批状态**: 待审批  
**负责人**: 待定  
**最后更新**: 2026 年 2 月 27 日
