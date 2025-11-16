LightRAG log file: /app/lightrag.log


    ╔══════════════════════════════════════════════════════════════╗
    ║                LightRAG Server v1.4.9.8/0251                 ║
    ║         Fast, Lightweight RAG Server Implementation          ║
    ╚══════════════════════════════════════════════════════════════╝


📡 Server Configuration:
    ├─ Host: 0.0.0.0
    ├─ Port: 9621
    ├─ Workers: 1
    ├─ Timeout: 300
    ├─ CORS Origins: *
    ├─ SSL Enabled: False
    ├─ Ollama Emulating Model: lightrag:latest
    ├─ Log Level: INFO
    ├─ Verbose Debug: False
    ├─ API Key: Not Set
    └─ JWT Auth: Disabled

INFO: OpenAI LLM Options: {'max_completion_tokens': 9000, 'temperature': 0.9}
📂 Directory Configuration:
    ├─ Working Directory: /app/data/rag_storage
    └─ Input Directory: /app/data/inputs

🤖 LLM Configuration:
    ├─ Binding: openai
    ├─ Host: https://api.openai.com/v1
    ├─ Model: gpt-4.1-mini
    ├─ Max Async for LLM: 16
    ├─ Summary Context Size: 12000
    ├─ LLM Cache Enabled: True
    └─ LLM Cache for Extraction Enabled: True

📊 Embedding Configuration:
    ├─ Binding: openai
    ├─ Host: https://api.openai.com/v1
    ├─ Model: text-embedding-3-small
    └─ Dimensions: 1536

⚙️ RAG Configuration:
    ├─ Summary Language: Português
    ├─ Entity Types: ['Variedade', 'Cultivar', 'Praga', 'Doença', 'TecnicaAgricola', 'EquipamentoAgricola', 'Fertilizante', 'Defensivo', 'Herbicida', 'Fungicida', 'Inseticida', 'Produto', 'SubprodutoMandioca', 'LocalidadeGeografica', 'TipoSolo', 'CondicaoClimatica', 'EpocaPlantio', 'PraticaManejo', 'Metrica', 'Instituicao', 'Pesquisador', 'Propriedade', 'ProcessamentoIndustrial']
    ├─ Max Parallel Insert: 6
    ├─ Chunk Size: 1200
    ├─ Chunk Overlap Size: 100
    ├─ Cosine Threshold: 0.2
    ├─ Top-K: 40
    └─ Force LLM Summary on Merge: 8

💾 Storage Configuration:
    ├─ KV Storage: PGKVStorage
    ├─ Vector Storage: PGVectorStorage
    ├─ Graph Storage: Neo4JStorage
    ├─ Document Status Storage: PGDocStatusStorage
    └─ Workspace: -

✨ Server starting up...


🌐 Server Access Information:
    ├─ WebUI (local): http://localhost:9621
    ├─ Remote Access: http://<your-ip-address>:9621
    ├─ API Documentation (local): http://localhost:9621/docs
    └─ Alternative Documentation (local): http://localhost:9621/redoc

📝 Note:
    Since the server is running on 0.0.0.0:
    - Use 'localhost' or '127.0.0.1' for local access
    - Use your machine's IP address for remote access
    - To find your IP address:
      • Windows: Run 'ipconfig' in terminal
      • Linux/Mac: Run 'ifconfig' or 'ip addr' in terminal

INFO: Send embedding dimension: False by env var (dimensions=1536, has_param=True, binding=openai)
INFO: Reranking is enabled: rerank-multilingual-v3.0 using cohere provider
INFO: Started server process [1]
INFO: Waiting for application startup.
INFO: PostgreSQL, Retry config: attempts=3, backoff=0.5s, backoff_max=5.0s, pool_close_timeout=5.0s
INFO: PostgreSQL, VECTOR extension enabled
INFO: PostgreSQL, Connected to database at postgres:5432/lightrag without SSL
INFO: PostgreSQL, Create vector indexs, type: HNSW
INFO: HNSW vector index idx_lightrag_vdb_chunks_hnsw_cosine already exists on table LIGHTRAG_VDB_CHUNKS
INFO: HNSW vector index idx_lightrag_vdb_entity_hnsw_cosine already exists on table LIGHTRAG_VDB_ENTITY
INFO: HNSW vector index idx_lightrag_vdb_relation_hnsw_cosine already exists on table LIGHTRAG_VDB_RELATION
INFO: chunk_id column already exists in LIGHTRAG_LLM_CACHE table
INFO: cache_type column already exists in LIGHTRAG_LLM_CACHE table
INFO: queryparam column already exists in LIGHTRAG_LLM_CACHE table
INFO: mode column does not exist in LIGHTRAG_LLM_CACHE table
INFO: Skipping migration: LIGHTRAG_VDB_CHUNKS already contains data.
INFO: chunks_list column already exists in LIGHTRAG_DOC_STATUS table
INFO: llm_cache_list column already exists in LIGHTRAG_DOC_CHUNKS table
INFO: track_id column already exists in LIGHTRAG_DOC_STATUS table
INFO: Index on track_id column already exists for LIGHTRAG_DOC_STATUS table
INFO: metadata column already exists in LIGHTRAG_DOC_STATUS table
INFO: error_msg column already exists in LIGHTRAG_DOC_STATUS table
INFO: [base] Connected to neo4j at neo4j://neo4j:7687
INFO: [base] Ensured B-Tree index on entity_id for base in neo4j
INFO: [base] Found existing index 'entity_id_fulltext_idx' with state: ONLINE
INFO: [base] Full-text index 'entity_id_fulltext_idx' already exists and is online. Skipping recreation.
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:9621 (Press CTRL+C to quit)
INFO: Starting multimodal processing: match_ec.pdf
INFO: MinerU parsed 307 content blocks
INFO: Content breakdown: 211 text, 0 images, 20 tables, 0 equations
INFO: LLM func: 16 new workers initialized (Timeouts: Func: 180s, Worker: 360s, Health Check: 375s)
INFO: Embedding func: 8 new workers initialized (Timeouts: Func: 30s, Worker: 60s, Health Check: 75s)
INFO:  == LLM cache == saving: default:extract:a2c9e4f1dceb5499508ac1c519a41832
INFO:  == LLM cache == saving: default:extract:023c5440820d66df42a51d42b2b6c37f
INFO: Chunk 1 of 1 extracted 5 Ent + 7 Rel chunk-341b533756c495f36429100c64e8eafd
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 5 entities from None (async: 32)
INFO: Phase 2: Processing 12 relations from None (async: 32)
INFO: Completed merging: 5 entities, 0 extra entities, 12 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:3197c5802f8191cc8461dfb444f5fdce
INFO:  == LLM cache == saving: default:extract:680d1c63acffdd7a6c51328d8b7d1be6
INFO: Chunk 1 of 1 extracted 41 Ent + 48 Rel chunk-ffc40ea658a86d8eca3ebb25703b99fb
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 41 entities from None (async: 32)
INFO: Merged: `Algodão` | 1+1
INFO: Merged: `Batata` | 1+1
INFO: Merged: `Aveia` | 1+1
INFO: Merged: `Eucalipto` | 1+1
INFO: Phase 2: Processing 83 relations from None (async: 32)
INFO: Merged: `Agronomic Pest Management Guidelines by Crop and Pest (table)`~`Algodão` | 1+1
INFO: Merged: `Agronomic Pest Management Guidelines by Crop and Pest (table)`~`Aveia` | 1+1
INFO: Merged: `Agronomic Pest Management Guidelines by Crop and Pest (table)`~`Batata` | 1+1
INFO: Merged: `Agronomic Pest Management Guidelines by Crop and Pest (table)`~`Eucalipto` | 1+1
INFO: Completed merging: 41 entities, 0 extra entities, 83 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:808d8682c667f52f5a277bf70e144ee7
INFO:  == LLM cache == saving: default:extract:c3f439fba2b07a36639e6d0e96f71528
INFO: Chunk 1 of 1 extracted 1 Ent + 0 Rel chunk-3af90be188a31276fa4b57eec2838eda
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 1 entities from None (async: 32)
INFO: Phase 2: Processing 1 relations from None (async: 32)
INFO: Completed merging: 1 entities, 0 extra entities, 1 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:dac369b3a951fa304dfeebac985ce07b
INFO:  == LLM cache == saving: default:extract:e408e56ae8a8aa977007677930a41b85
INFO: Chunk 1 of 1 extracted 2 Ent + 1 Rel chunk-1339d60164d7e0bc67a7201d0565af46
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 2 entities from None (async: 32)
INFO: Merged: `Tabela` | 1+1
INFO: Phase 2: Processing 3 relations from None (async: 32)
INFO: Merged: `Tabela`~`Unavailable - No Table Provided (table)` | 1+1
INFO: Completed merging: 2 entities, 0 extra entities, 3 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:716f39ea4ff9c3652f0969290d61a1d0
INFO:  == LLM cache == saving: default:extract:222377c57a638bb554f4f53871989472
INFO: Chunk 1 of 1 extracted 1 Ent + 1 Rel chunk-3258f51e131028718e3f8534a40ccb9a
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 1 entities from None (async: 32)
INFO: Merged: `Tabela` | 2+1
INFO: Phase 2: Processing 2 relations from None (async: 32)
INFO: Merged: `Empty Table with No Data (table)`~`Tabela` | 1+1
INFO: Completed merging: 1 entities, 1 extra entities, 2 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:45ff89280e4d0dfad236a438dafbe00c
INFO:  == LLM cache == saving: default:extract:c637aeb3a7de6d5532a6a53bfe156d65
INFO: Chunk 1 of 1 extracted 1 Ent + 0 Rel chunk-f5583ee0b3949212001c5da2ef00d9c3
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 1 entities from None (async: 32)
INFO: Merged: `Tabela` | 3+1
INFO: Phase 2: Processing 1 relations from None (async: 32)
INFO: Merged: `Tabela`~`Unavailable Table Content (table)` | 1+1
INFO: Completed merging: 1 entities, 0 extra entities, 1 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:6beb48ea76bee8a114a8ddb03b6ec230
INFO:  == LLM cache == saving: default:extract:b831b4fb6a84ce31320dff82b1116efa
INFO: Chunk 1 of 1 extracted 4 Ent + 3 Rel chunk-c986adaadd73bbe0bad91741065aa39f
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 4 entities from None (async: 32)
INFO: Merged: `Tabela` | 4+1
INFO: Merged: `Análise` | 1+1
INFO: Phase 2: Processing 7 relations from None (async: 32)
INFO: Merged: `Análise`~`Tabela` | 1+1
INFO: Merged: `Tabela`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Análise`~`Unavailable Table Data (table)` | 1+1
INFO: Completed merging: 4 entities, 0 extra entities, 7 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:b981dc865346e80d7613d8df2be5b281
INFO:  == LLM cache == saving: default:extract:05164813e6c9975bbbe55617bf9965ac
INFO: Chunk 1 of 1 extracted 6 Ent + 5 Rel chunk-3d472f59145556c84fa8ee5b68452911
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 6 entities from None (async: 32)
INFO: Phase 2: Processing 11 relations from None (async: 32)
INFO: Completed merging: 6 entities, 0 extra entities, 11 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:747011c529fc0edfe78d40600bcaf747
INFO:  == LLM cache == saving: default:extract:03f7ade8cdf6425d08477d86f6cc775e
INFO: Chunk 1 of 1 extracted 16 Ent + 27 Rel chunk-fd4ced8579e6e108faea15a7be5977f3
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 16 entities from None (async: 32)
INFO: Merged: `Mariposa-Oriental` | 1+1
INFO: Merged: `Lagarta-Militar` | 1+1
INFO: Merged: `Volume de Calda` | 1+1
INFO: Phase 2: Processing 43 relations from None (async: 32)
INFO: Merged: `Crop Pest Management and Pesticide Application Guidelines (table)`~`Mariposa-Oriental` | 1+1
INFO: Merged: `Crop Pest Management and Pesticide Application Guidelines (table)`~`Lagarta-Militar` | 1+1
INFO: Merged: `Crop Pest Management and Pesticide Application Guidelines (table)`~`Volume de Calda` | 1+1
INFO: Completed merging: 16 entities, 0 extra entities, 43 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:f59998f80e67ce97edda7a0a151a4f49
INFO:  == LLM cache == saving: default:extract:310cf23951dbe93ec494b496821ddb19
INFO: Chunk 1 of 1 extracted 14 Ent + 18 Rel chunk-b5f22c6d15d002d07736544257ec73c4
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 14 entities from None (async: 32)
INFO: Merged: `Pulverização Terrestre` | 1+1
INFO: Phase 2: Processing 32 relations from None (async: 32)
INFO: Merged: `Pesticide Application Guidelines for Selected Crops and Pests (table)`~`Pulverização Terrestre` | 1+1
INFO: Completed merging: 14 entities, 0 extra entities, 32 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:295476c85680ab94e19b388dbb70f7c0
INFO:  == LLM cache == saving: default:extract:871bc666ab6766f61c252497c886aaf4
INFO: Chunk 1 of 1 extracted 21 Ent + 21 Rel chunk-8cd99297551cfa6362b33833460c6e4d
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 21 entities from None (async: 32)
INFO: Merged: `Mariposa-Oriental` | 2+1
INFO: Merged: `Lagarta-Militar` | 2+1
INFO: Merged: `Tripes` | 1+1
INFO: Merged: `Dose 100mL/100L` | 1+1
INFO: Phase 2: Processing 42 relations from None (async: 32)
INFO: Merged: `Pesticide Application Guidelines for Crop and Ornamental Plant Pest Control (table)`~`Tripes` | 1+1
INFO: Merged: `Lagarta-Militar`~`Pesticide Application Guidelines for Crop and Ornamental Plant Pest Control (table)` | 1+1
INFO: Merged: `Mariposa-Oriental`~`Pesticide Application Guidelines for Crop and Ornamental Plant Pest Control (table)` | 1+1
INFO: Merged: `Dose 100mL/100L`~`Pesticide Application Guidelines for Crop and Ornamental Plant Pest Control (table)` | 1+1
INFO: Completed merging: 21 entities, 0 extra entities, 42 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:6feee120ab0aff2be5f1083449d78168
INFO:  == LLM cache == saving: default:extract:c2637ab2833d0d9fe8f88a7c26c56361
INFO: Chunk 1 of 1 extracted 24 Ent + 20 Rel chunk-1f943e090380ef8944bd857967f9a278
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 24 entities from None (async: 32)
INFO: Merged: `Lagarta-das-Palmeiras` | 1+1
INFO: Merged: `Lagarta-do-Coqueiro` | 1+1
INFO: Merged: `Traça-das-Crucíferas` | 1+1
INFO: Merged: `Lagarta-Militar` | 3+1
INFO: Merged: `Broca-da-Cana` | 1+1
INFO: Merged: `Tripes` | 2+1
INFO: Merged: `Soja` | 1+1
INFO: Merged: `Lagarta-das-Folhas` | 1+1
INFO: Merged: `Tomate` | 1+1
INFO: Merged: `Lagarta-do-Trigo` | 1+1
INFO: Merged: `Volume de Calda` | 2+1
INFO: Merged: `Época e Intervalo de Aplicação` | 1+1
INFO: Phase 2: Processing 44 relations from None (async: 32)
INFO: Chunks appended from relation: `Cultivar`
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Lagarta-das-Palmeiras` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Lagarta-do-Coqueiro` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Traça-das-Crucíferas` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Lagarta-Militar` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Tripes` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Soja` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Lagarta-das-Folhas` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Tomate` | 1+1
INFO: Merged: `Broca-da-Cana`~`Crop-specific Pest Control Application Guidelines (table)` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Lagarta-do-Trigo` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Volume de Calda` | 1+1
INFO: Merged: `Crop-specific Pest Control Application Guidelines (table)`~`Época e Intervalo de Aplicação` | 1+1
INFO: Completed merging: 24 entities, 1 extra entities, 44 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:979519f328ca569d47b28b917602e988
INFO:  == LLM cache == saving: default:extract:1142f83c954ffcd29b0defab7d09716e
INFO: Chunk 1 of 1 extracted 0 Ent + 0 Rel chunk-55b9588f004ee731d02242fed48afa96
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 0 entities from None (async: 32)
INFO: Phase 2: Processing 0 relations from None (async: 32)
INFO: Completed merging: 0 entities, 0 extra entities, 0 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:cddc364c5084b2d4b5edef43d1976218
INFO:  == LLM cache == saving: default:extract:730e710f6552cd016f4d6ba17f6296d2
INFO: Chunk 1 of 1 extracted 5 Ent + 4 Rel chunk-588c36b458485e7b4c53897dd5f346a2
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 5 entities from None (async: 32)
INFO: Merged: `Table Analysis` | 1+1
INFO: Merged: `Image Path` | 1+1
INFO: Merged: `Caption` | 1+1
INFO: Merged: `Footnotes` | 1+1
INFO: Phase 2: Processing 9 relations from None (async: 32)
INFO: Merged: `Image Path`~`Table Analysis` | 1+1
INFO: Merged: `Caption`~`Table Analysis` | 1+1
INFO: Merged: `Footnotes`~`Table Analysis` | 1+1
INFO: Merged: `Missing Table Data (table)`~`Table Analysis` | 1+1
INFO: Merged: `Image Path`~`Missing Table Data (table)` | 1+1
INFO: Merged: `Caption`~`Missing Table Data (table)` | 1+1
INFO: Merged: `Footnotes`~`Missing Table Data (table)` | 1+1
INFO: Completed merging: 5 entities, 0 extra entities, 9 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:2fabadf6a087843bbd9a2f104edbba4d
INFO:  == LLM cache == saving: default:extract:4c8b70c950c08d5cb3d3ebb5aba6072e
INFO: Chunk 1 of 1 extracted 43 Ent + 41 Rel chunk-fa3e09545803e0385da34d6f0d1a2d75
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 43 entities from None (async: 32)
INFO: Merged: `Abóbora` | 1+1
INFO: Merged: `Algodão` | 2+1
INFO: Merged: `Aveia` | 2+1
INFO: Merged: `Abobrinha` | 1+1
INFO: Merged: `Cana-de-Açúcar` | 1+1
INFO: Merged: `Batata` | 2+1
INFO: Merged: `Centeio` | 1+1
INFO: Merged: `Brócolis` | 1+1
INFO: Merged: `Ameixa` | 1+1
INFO: Merged: `Couve-Chinesa` | 1+1
INFO: Merged: `Cevada` | 1+1
INFO: Merged: `Crisântemo` | 1+1
INFO: Merged: `Eucalipto` | 2+1
INFO: Merged: `Coco` | 1+1
INFO: Merged: `Citros` | 1+1
INFO: Merged: `Nectarina` | 1+1
INFO: Merged: `Pepino` | 1+1
INFO: Merged: `Marmelo` | 1+1
INFO: Merged: `Couve` | 1+1
INFO: Merged: `Couve-Flor` | 1+1
INFO: Merged: `Milho` | 1+1
INFO: Merged: `Maxixe` | 1+1
INFO: Merged: `Milheto` | 1+1
INFO: Merged: `Maçã` | 1+1
INFO: Merged: `Plantas Ornamentais` | 1+1
INFO: Merged: `Pupunha` | 1+1
INFO: Merged: `Repolho` | 1+1
INFO: Merged: `Rosa` | 1+1
INFO: Merged: `Soja` | 2+1
INFO: Merged: `Sorgo` | 1+1
INFO: Merged: `Tomate` | 2+1
INFO: Merged: `Trigo` | 1+1
INFO: Merged: `Triticale` | 1+1
INFO: Phase 2: Processing 84 relations from None (async: 32)
INFO: Merged: `Abóbora`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Abobrinha`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Algodão`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Ameixa`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Aveia`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Batata`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Brócolis`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Cana-de-Açúcar`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Centeio`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Cevada`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Citros`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Coco`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Crisântemo`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Couve`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Couve-Chinesa`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Couve-Flor`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Eucalipto`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Maçã`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Maxixe`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Marmelo`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Milheto`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Milho`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Nectarina`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Pepino`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Plantas Ornamentais`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Pupunha`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Repolho`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Rosa`~`Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)` | 1+1
INFO: Merged: `Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)`~`Soja` | 1+1
INFO: Merged: `Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)`~`Sorgo` | 1+1
INFO: Merged: `Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)`~`Tomate` | 1+1
INFO: Merged: `Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)`~`Trigo` | 1+1
INFO: Merged: `Safety Interval Periods Between Last Agrochemical Application and Harvest for Various Crops (table)`~`Triticale` | 1+1
INFO: Completed merging: 43 entities, 0 extra entities, 84 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:26f9080f256fc73792ee86d91ba0de1b
INFO:  == LLM cache == saving: default:extract:964cd703578471c06679e7446ef06870
INFO: Chunk 1 of 1 extracted 0 Ent + 0 Rel chunk-5455e1ac6d7fe327d7a2dc2aa2e9b369
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 0 entities from None (async: 32)
INFO: Phase 2: Processing 0 relations from None (async: 32)
INFO: Completed merging: 0 entities, 0 extra entities, 0 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO: 149.19.164.252:49306 - "GET /webui/assets/index-DR3jZfSQ.js HTTP/1.1" 304
INFO: 149.19.164.252:59185 - "GET /webui/assets/index-BCl2jSEs.css HTTP/1.1" 304
INFO: 149.19.164.252:59185 - "GET /webui/favicon.png HTTP/1.1" 304
INFO: 149.19.164.252:49306 - "GET /docs HTTP/1.1" 200
INFO: 149.19.164.252:41031 - "GET /webui/assets/index-DUZt-ONn.js HTTP/1.1" 304
INFO: 149.19.164.252:49306 - "GET /openapi.json HTTP/1.1" 200
INFO: [base] Subgraph query successful | Node count: 970 | Edge count: 978
INFO: 149.19.164.252:12538 - "GET /graphs?label=*&max_depth=3&max_nodes=1000 HTTP/1.1" 200
INFO:  == LLM cache == saving: default:extract:ec5d63ff854ce28957b5665a89a37d10
INFO:  == LLM cache == saving: default:extract:b34033f44b131b8287ec35cc6c1681cb
INFO: Chunk 1 of 1 extracted 21 Ent + 19 Rel chunk-3804d2bb89a94bc7a2b3740b559c3a70
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 21 entities from None (async: 32)
INFO: Phase 2: Processing 40 relations from None (async: 32)
INFO:  == LLM cache == saving: mix:keywords:21d3525ea73663f55b5f0765c9ba96af
INFO: Query nodes: match (top_k:40, cosine:0.2)
INFO: Local query: 40 entites, 62 relations
INFO: Query edges: Intervalo de segurança, Análise de segurança, Avaliação de risco (top_k:40, cosine:0.2)
INFO: Global query: 43 entites, 40 relations
INFO: Naive query: 20 chunks (chunk_top_k:20 cosine:0.2)
INFO: Raw search results: 80 entities, 99 relations, 20 vector chunks
INFO: After truncation: 77 entities, 99 relations
WARNING: Vector similarity chunk selection: found 26 but expecting 27
WARNING: No entity-related chunks selected by vector similarity, falling back to WEIGHT method
INFO: Selecting 27 from 27 entity-related chunks by weighted polling
INFO: Find no additional relations-related chunks from 99 relations
INFO: Round-robin merged chunks: 46 -> 35 (deduplicated 11)
INFO: Successfully reranked: 20 chunks from 35 original chunks
INFO: Final context: 77 entities, 99 relations, 6 chunks
INFO: Final chunks S+F/O: E37/2 E14/8 E4/5 E2/21 C1/13 E7/10
INFO: Completed merging: 21 entities, 0 extra entities, 40 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: mix:query:924d61be6a4ceb6179fdf7a1bdeff78f
INFO: 149.19.164.252:29125 - "POST /query/stream HTTP/1.1" 200
INFO:  == LLM cache == saving: default:extract:ceb2f551c9e098bfe0864bdba8998539
INFO:  == LLM cache == saving: default:extract:ffeced0e02c379389972d95a39d5b927
INFO: Chunk 1 of 1 extracted 0 Ent + 0 Rel chunk-92f71285a04c31af10d14e12a830647a
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 0 entities from None (async: 32)
INFO: Phase 2: Processing 0 relations from None (async: 32)
INFO: Completed merging: 0 entities, 0 extra entities, 0 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:8c1a173ba25b736e35322ae969e9d538
INFO:  == LLM cache == saving: default:extract:595aea5aa415f8a45ebf9685b828e4b3
INFO: Chunk 1 of 1 extracted 3 Ent + 2 Rel chunk-af0b57e7ea32dcf253c28bc468eefd05
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 3 entities from None (async: 32)
INFO: Merged: `Imagem` | 1+1
INFO: Merged: `Análise` | 2+1
INFO: Merged: `Tabela` | 5+1
INFO: Phase 2: Processing 5 relations from None (async: 32)
INFO: Merged: `Análise`~`Tabela` | 2+1
INFO: Merged: `Imagem`~`Tabela` | 1+1
INFO: Merged: `Análise`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Tabela`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Imagem`~`Unavailable Table Data (table)` | 1+1
INFO: Completed merging: 3 entities, 0 extra entities, 5 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO:  == LLM cache == saving: default:extract:7ef123d539c22ebfa998c4518dab9b30
INFO:  == LLM cache == saving: default:extract:80e903c99a0291ba5f969db4adcaa6ea
INFO: Chunk 1 of 1 extracted 5 Ent + 4 Rel chunk-d5340936583bce59d45bc777c8e33553
INFO: Merging stage 1/1: match_ec.pdf
INFO: Phase 1: Processing 5 entities from None (async: 32)
INFO: Merged: `Table Analysis` | 2+1
INFO: Merged: `Caption` | 2+1
INFO: Merged: `Image Path` | 2+1
INFO: Merged: `Structure` | 1+1
INFO: Merged: `Footnotes` | 2+1
INFO: Phase 2: Processing 9 relations from None (async: 32)
INFO: Merged: `Image Path`~`Table Analysis` | 2+1
INFO: Merged: `Caption`~`Table Analysis` | 2+1
INFO: Merged: `Image Path`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Structure`~`Table Analysis` | 1+1
INFO: Merged: `Caption`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Footnotes`~`Table Analysis` | 2+1
INFO: Merged: `Structure`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Table Analysis`~`Unavailable Table Data (table)` | 1+1
INFO: Merged: `Footnotes`~`Unavailable Table Data (table)` | 1+1
INFO: Completed merging: 5 entities, 0 extra entities, 9 relations
INFO: In memory DB persist to disk
WARNING: Failed to process table: too many values to unpack (expected 2)
INFO: Multimodal processing complete: match_ec.pdf