# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LightRAG is a graph-based Retrieval-Augmented Generation (RAG) system that combines knowledge graphs with vector embeddings for enhanced document retrieval and question answering.

## Development Commands

### Environment Setup
```bash
python -m venv .venv && source .venv/bin/activate
pip install -e .              # Core package
pip install -e .[api]         # With API server
cp env.example .env           # Configure before running
```

### Running the Server
```bash
lightrag-server                                       # Simple (Uvicorn)
lightrag-gunicorn --workers 4                        # Production (Gunicorn)
uvicorn lightrag.api.lightrag_server:app --reload   # Development
```

### Testing
```bash
python -m pytest tests                 # Full suite
python test_graph_storage.py          # Single test
ruff check .                           # Lint
```

### Frontend (WebUI)
```bash
cd lightrag_webui
bun install --frozen-lockfile
bun run dev      # Development server
bun run build    # Production build → lightrag/api/webui
bun test         # Run tests
```

### Docker Deployment
```bash
# Standalone (in-memory databases)
docker compose up

# Full stack (PostgreSQL + Neo4j)
docker compose -f docker-compose.full.yml up -d

# Production optimized
docker compose -f docker-compose.prod.yml up -d
```

## Architecture

### Core Components

**`lightrag/lightrag.py`** - Main orchestrator class
- Document indexing pipeline
- Query execution (6 modes: local, global, hybrid, naive, mix, bypass)
- Storage initialization
- Entity/relation CRUD operations

**`lightrag/operate.py`** - Core algorithms
- Document chunking (default: 1200 tokens, 100 overlap)
- Entity extraction via LLM
- Entity merging and deduplication
- Query processing logic

**`lightrag/base.py`** - Storage abstractions
- Defines interfaces for all storage types
- Extend these classes when adding new storage backends

### Storage Layer (4 Types)

1. **KV_STORAGE** - Key-value store for LLM cache, chunks, metadata
   - Implementations: Json (default), PostgreSQL, Redis, MongoDB

2. **VECTOR_STORAGE** - Vector embeddings for entities, relations, chunks
   - Implementations: NanoVectorDB (default), PostgreSQL+pgvector, Milvus, FAISS, Qdrant, MongoDB

3. **GRAPH_STORAGE** - Knowledge graph for entities and relationships
   - Implementations: NetworkX (default), Neo4j (recommended for production), PostgreSQL+AGE, Memgraph

4. **DOC_STATUS_STORAGE** - Document processing status tracking
   - Implementations: Json (default), PostgreSQL, MongoDB

**Configuration Pattern:**
```bash
# .env file
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage
```

### API Server (`lightrag/api/`)

**FastAPI application** with:
- JWT authentication (`auth.py`)
- API key protection
- Ollama-compatible endpoints (`routers/ollama_api.py`)
- Document management (`routers/document_routes.py`)
- Query endpoints (`routers/query_routes.py`)
- Graph visualization (`routers/graph_routes.py`)

**Configuration priority:** CLI args > Environment variables (.env) > config.ini

### LLM Integrations (`lightrag/llm/`)

Supported providers:
- OpenAI and compatible APIs (`openai.py`)
- Azure OpenAI (`azure_openai.py`)
- Ollama local models (`ollama.py`)
- Google Gemini (`gemini.py`)
- Anthropic Claude (`anthropic.py`)
- AWS Bedrock (`bedrock.py`)
- Hugging Face (`hf.py`)

## Critical Constraints

1. **Embedding model cannot change after indexing** - The embedding dimension and model must remain fixed once documents are indexed

2. **Initialization required** - Always call both:
   ```python
   await rag.initialize_storages()
   await initialize_pipeline_status()
   ```

3. **Storage type immutability** - Cannot migrate between storage implementations (e.g., NetworkX → Neo4j) without re-indexing

4. **Workspace immutability** - Workspace name is fixed after creation

5. **LLM requirements** - Needs capable models (32B+ parameters recommended, 32KB+ context)

## Common Development Tasks

### Adding a Storage Backend

1. Create new file in `lightrag/kg/` (e.g., `new_storage_impl.py`)
2. Extend base classes from `lightrag/base.py`:
   - `BaseKVStorage`
   - `BaseVectorStorage`
   - `BaseGraphStorage`
   - `BaseDocStatusStorage`
3. Follow pattern from `postgres_impl.py` or `neo4j_impl.py`
4. Register in `lightrag/__init__.py`
5. Add tests in `tests/`

### Adding an LLM Provider

1. Create new file in `lightrag/llm/` (e.g., `new_provider.py`)
2. Follow structure from `openai.py`:
   - Implement `llm_model_function` with streaming support
   - Implement `embedding_function`
   - Add binding options in `binding_options.py`
3. Update CLI help in `lightrag/api/config.py`

### Adding an API Endpoint

1. Add route in appropriate router file in `lightrag/api/routers/`
2. Use dependency injection for authentication:
   ```python
   @router.post("/endpoint")
   async def my_endpoint(
       auth_context: Annotated[AuthContext, Depends(verify_auth)],
   ):
       ...
   ```
3. Add to API documentation

### Modifying Frontend

1. Components live in `lightrag_webui/src/`
2. Use React 19 + TypeScript with hooks
3. Follow Tailwind utility-first CSS
4. Build before deploying: `bun run build`

## Environment Variables Reference

**Critical Configuration:**
```bash
# LLM
LLM_BINDING=openai
LLM_MODEL=gpt-4o-mini
LLM_BINDING_HOST=https://api.openai.com/v1
LLM_BINDING_API_KEY=sk-...

# Embedding
EMBEDDING_BINDING=openai
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_DIM=3072
EMBEDDING_BINDING_API_KEY=sk-...

# Storage Selection
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=lightrag
POSTGRES_PASSWORD=password
POSTGRES_DATABASE=lightrag

# Neo4j
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=password
NEO4J_DATABASE=neo4j

# Query Parameters
TOP_K=40                    # Entities/relations retrieved
CHUNK_TOP_K=20             # Chunks retrieved
MAX_ENTITY_TOKENS=6000     # Entity context budget
MAX_RELATION_TOKENS=8000   # Relation context budget
MAX_TOTAL_TOKENS=30000     # Total LLM context

# Processing
MAX_ASYNC=4                # Concurrent LLM calls
MAX_PARALLEL_INSERT=2      # Parallel document processing
CHUNK_SIZE=1200            # Tokens per chunk
CHUNK_OVERLAP_SIZE=100     # Overlap between chunks

# Authentication (optional)
AUTH_ACCOUNTS='admin:password,user:pass'
LIGHTRAG_API_KEY=your-api-key
TOKEN_SECRET=your-jwt-secret
```

## Docker Deployment Notes

### Full Stack Setup (PostgreSQL + Neo4j)

1. **Directory structure:**
   ```bash
   mkdir -p /opt/lightrag/data/{postgres,neo4j,rag_storage,inputs,tiktoken}
   mkdir -p /opt/lightrag/logs/neo4j
   chmod -R 777 /opt/lightrag/{data,logs}
   ```

2. **Environment configuration:**
   - Copy `env.example` to `.env`
   - Configure all required variables (LLM, embedding, database passwords)
   - Use strong passwords for `POSTGRES_PASSWORD` and `NEO4J_PASSWORD`

3. **Deploy:**
   ```bash
   docker compose -f docker-compose.full.yml up -d
   ```

4. **Verify:**
   ```bash
   docker compose -f docker-compose.full.yml ps
   docker logs lightrag --tail 50
   ```

### Common Docker Issues

**Neo4j healthcheck failures:**
- Neo4j does not accept `NEO4J_PASSWORD` as environment variable
- Only `NEO4J_AUTH=username/password` is valid
- Healthcheck must include credentials:
  ```yaml
  healthcheck:
    test: ["CMD-SHELL", "cypher-shell -u neo4j -p 'password' -a bolt://localhost:7687 'RETURN 1' || exit 1"]
  ```
- Or use HTTP-based healthcheck:
  ```yaml
  healthcheck:
    test: ["CMD-SHELL", "wget --spider -q http://localhost:7474 || exit 1"]
  ```

**PostgreSQL database not found:**
- Ensure `POSTGRES_DATABASE` in `.env` matches `POSTGRES_DB` in docker-compose
- Default is `lightrag`, not `lightrag_db`

**Container hostname resolution:**
- Use service names as hostnames: `postgres`, `neo4j`, `lightrag`
- Example: `NEO4J_URI=bolt://neo4j:7687` (not `bolt://dozerdb:7687`)

## Workspace Isolation

Multiple LightRAG instances can share storage using workspaces:

```bash
lightrag-server --port 9621 --workspace project1
lightrag-server --port 9622 --workspace project2
```

Implementation varies by storage backend:
- File-based: Subdirectories
- Collections: Prefix on collection name
- Relational DB: `workspace` column filter
- Neo4j: Node labels
- Qdrant: Payload filtering

## Query Modes

Six query modes available via `QueryParam(mode="...")`:

1. **local** - Context-dependent entity retrieval (high relevance)
2. **global** - Global knowledge from relationships (broad coverage)
3. **hybrid** - Combines local + global
4. **naive** - Simple vector search on chunks only
5. **mix** - KG + vector retrieval (recommended for best results)
6. **bypass** - Direct LLM query without RAG

## Testing Strategy

- `tests/` contains pytest test cases
- Root-level `test_*.py` for integration tests
- Export required environment variables before running storage tests
- Use `pytest -v` for verbose output
- Test single file: `python test_graph_storage.py`

## Code Style

**Python:**
- Follow PEP 8, four-space indentation
- Type annotations required
- Use `lightrag.utils.logger` instead of `print()`
- Dataclasses for state modeling
- Async/await for I/O operations

**TypeScript (Frontend):**
- Two-space indentation
- Functional components with hooks
- PascalCase for components
- Tailwind utility-first CSS

## Security

- Never commit `.env` or `config.ini` with real credentials
- Use strong passwords for databases
- Rotate API keys regularly
- Treat `lightrag.log*` as sensitive
- Validate all user inputs in API endpoints
- Use JWT authentication for production deployments
