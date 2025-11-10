# Correções para Deployment em Produção

## Mudanças Necessárias Identificadas em 08/11/2025

### 1. ❌ PROBLEMA: Neo4j Healthcheck com Autenticação
**Arquivo:** `docker-compose.full.yml`

**Problema:**
- O healthcheck atual usa `cypher-shell` com senha via `$$NEO4J_PASSWORD`
- A variável `NEO4J_PASSWORD` não existe dentro do container Neo4j
- Neo4j só aceita `NEO4J_AUTH=username/password`
- Tentativas repetidas de autenticação causam bloqueio temporário
- LightRAG não inicia porque depende do healthcheck do Neo4j

**Healthcheck ATUAL (com problema):**
```yaml
healthcheck:
  test: ["CMD-SHELL", "cypher-shell -u neo4j -p $$NEO4J_PASSWORD -a neo4j://neo4j:7687 'RETURN 1' 2>/dev/null || exit 1"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

**Healthcheck CORRIGIDO (funciona):**
```yaml
healthcheck:
  test: ["CMD-SHELL", "wget --spider -q http://localhost:7474 || exit 1"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

**Por quê funciona:**
- Usa HTTP endpoint (porta 7474) que não requer autenticação
- Verifica apenas se o Neo4j está respondendo
- Sem risco de bloqueio por tentativas de autenticação
- Mais confiável e rápido

---

### 2. ⚠️ AVISO: Embedding Dimensions vs PostgreSQL HNSW

**Arquivo:** `env.example`

**Problema:**
- PostgreSQL pgvector com índice HNSW suporta **máximo 2000 dimensões**
- O exemplo atual mostra `text-embedding-3-large` com **3072 dimensões**
- Isso causa erro na criação de índices vetoriais:
  ```
  ERROR: column cannot have more than 2000 dimensions for hnsw index
  ```

**Recomendação ATUAL no env.example:**
```bash
### OpenAI compatible (VoyageAI embedding openai compatible)
# EMBEDDING_BINDING=openai
# EMBEDDING_MODEL=text-embedding-3-large   # ← 3072 dimensions - NÃO FUNCIONA COM HNSW!
# EMBEDDING_DIM=3072
```

**Recomendação CORRIGIDA:**
```bash
### OpenAI compatible (VoyageAI embedding openai compatible)
# EMBEDDING_BINDING=openai
# EMBEDDING_MODEL=text-embedding-3-small   # ← 1536 dimensions - FUNCIONA COM HNSW
# EMBEDDING_DIM=1536
# EMBEDDING_BINDING_HOST=https://api.openai.com/v1
# EMBEDDING_BINDING_API_KEY=your_api_key

### IMPORTANTE: PostgreSQL HNSW índice suporta máximo 2000 dimensões
### Para usar text-embedding-3-large (3072 dim), mude para IVFFlat:
# POSTGRES_VECTOR_INDEX_TYPE=IVFFlat
# EMBEDDING_MODEL=text-embedding-3-large
# EMBEDDING_DIM=3072
```

**Modelos recomendados para PostgreSQL + HNSW:**
- ✅ `text-embedding-3-small` (1536 dim) - Recomendado, rápido, barato
- ✅ `text-embedding-ada-002` (1536 dim) - Legacy, mas funciona
- ✅ `bge-m3:latest` via Ollama (1024 dim) - Local, grátis
- ⚠️ `text-embedding-3-large` (3072 dim) - **Requer IVFFlat**

---

### 3. 📝 Documentação Adicional no CLAUDE.md

**O que foi adicionado:**
- Seção "Common Docker Issues" com problemas encontrados:
  - Neo4j healthcheck failures
  - PostgreSQL database not found
  - Container hostname resolution
- Nota sobre limitação de dimensões do HNSW
- Solução alternativa com IVFFlat

---

## Checklist de Aplicação

- [ ] Atualizar healthcheck do Neo4j em `docker-compose.full.yml`
- [ ] Atualizar exemplo de embedding em `env.example` para text-embedding-3-small
- [ ] Adicionar comentário sobre limitação HNSW (2000 dimensões)
- [ ] Adicionar seção no README sobre escolha de embedding model
- [ ] Testar deployment limpo com as correções

---

## Testado em Produção

**Data:** 08/11/2025
**Servidor:** Hetzner VPS (116.203.193.178)
**OS:** Ubuntu 24.04.3 LTS
**RAM:** 74.79 GB
**Docker:** 27.3.1
**Docker Compose:** v2.40.3

**Stack:**
- PostgreSQL 16 + pgvector (HNSW)
- Neo4j 5.26.3 (DozerDB)
- LightRAG 1.4.9.8

**Resultado:**
✅ Todos os serviços rodando corretamente
✅ Índices vetoriais HNSW criados com sucesso
✅ API respondendo na porta 9621
✅ WebUI funcional
✅ Neo4j Healthy
✅ PostgreSQL Healthy

---

## Configuração Final Funcionando

### .env
```bash
# LLM
LLM_BINDING=openai
LLM_MODEL=gpt-4o-mini
LLM_BINDING_HOST=https://api.openai.com/v1
LLM_BINDING_API_KEY=sk-proj-xxxxx

# Embedding (CORRIGIDO)
EMBEDDING_BINDING=openai
EMBEDDING_MODEL=text-embedding-3-small  # ← 1536 dim
EMBEDDING_DIM=1536                       # ← Funciona com HNSW
EMBEDDING_BINDING_HOST=https://api.openai.com/v1
EMBEDDING_BINDING_API_KEY=sk-proj-xxxxx

# Storage
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage

# PostgreSQL
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=lightrag
POSTGRES_PASSWORD=SenhaForte123!
POSTGRES_DATABASE=lightrag              # ← NÃO lightrag_db

# Neo4j
NEO4J_URI=bolt://neo4j:7687             # ← NÃO bolt://dozerdb:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=SenhaForte456!
NEO4J_DATABASE=neo4j

# Rerank (opcional mas recomendado)
RERANK_BINDING=cohere
RERANK_MODEL=rerank-multilingual-v3.0
RERANK_BINDING_HOST=https://api.cohere.com/v2/rerank
RERANK_BINDING_API_KEY=xxxxx

# Processamento
SUMMARY_LANGUAGE=Português
MAX_ASYNC=16
MAX_PARALLEL_INSERT=6
```

### docker-compose.full.yml (Neo4j healthcheck section)
```yaml
  neo4j:
    image: graphstack/dozerdb:5.26.3.0
    container_name: lightrag-neo4j

    environment:
      NEO4J_AUTH: neo4j/${NEO4J_PASSWORD:-neo4j_secure_password_change_me}
      # NÃO adicione NEO4J_PASSWORD aqui - Neo4j não reconhece essa variável

    healthcheck:
      test: ["CMD-SHELL", "wget --spider -q http://localhost:7474 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

---

## Observações Importantes

1. **Embedding model é IMUTÁVEL após indexação**
   - Não é possível mudar depois de processar documentos
   - Requer reprocessamento completo se mudar

2. **Performance: text-embedding-3-small vs large**
   - Small (1536 dim): Rápido, barato, excelente qualidade
   - Large (3072 dim): Mais preciso, mais caro, requer IVFFlat
   - Para a maioria dos casos, Small é suficiente

3. **Custo por 1M tokens:**
   - text-embedding-3-small: $0.02
   - text-embedding-3-large: $0.13
   - **6.5x mais barato!**

4. **Senhas com caracteres especiais**
   - Neo4j aceita senhas com `*`, `!`, etc.
   - Mas use aspas no healthcheck se testar manualmente
   - Healthcheck HTTP evita esse problema completamente
