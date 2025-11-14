# 🚀 Como Instalar RAG-Anything no Seu LightRAG (Guia Simplificado)

## 📋 O que você vai fazer

1. Instalar RAG-Anything (1 comando)
2. Testar standalone (1 comando)
3. Adicionar ao servidor LightRAG (1 arquivo)
4. Usar via API (upload normal)

**Tempo total: 15 minutos**

---

## 🎯 Passo 1: Instalar RAG-Anything

```bash
cd /opt/lightrag  # ou onde seu LightRAG está

# Opção A: Instalação básica (rápida)
pip install raganything

# Opção B: Instalação completa (recomendado)
pip install 'raganything[all]'
```

**O que isso faz:**
- Instala RAG-Anything
- Instala MinerU (parsing avançado de PDFs)
- Instala dependências para processar imagens/tabelas

**Problemas comuns:**
```bash
# Se der erro de "magic-pdf"
pip install magic-pdf[full]

# Se der erro de "torch" (GPU opcional)
pip install torch torchvision  # ou skip se não tem GPU
```

---

## 🧪 Passo 2: Testar Standalone (Verificar que Funciona)

Crie um arquivo de teste simples:

```bash
cd /opt/lightrag
mkdir -p test_rag_anything
cd test_rag_anything
```

Crie arquivo `test_simple.py`:

```python
#!/usr/bin/env python
"""Teste simples do RAG-Anything"""
import asyncio
import os
from raganything import RAGAnything, RAGAnythingConfig
from lightrag.llm.openai import openai_complete_if_cache, openai_embed
from lightrag.utils import EmbeddingFunc

async def test_raganything():
    # 1. Configuração mínima
    config = RAGAnythingConfig(
        working_dir="./rag_test_storage",
        enable_image_processing=True,   # Processar imagens
        enable_table_processing=True,   # Processar tabelas
        enable_equation_processing=False, # Desabilitar equações (economizar)
    )

    # 2. LLM function (mesma que você usa no LightRAG)
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("LLM_BINDING_API_KEY")
    base_url = os.getenv("LLM_BINDING_HOST", "https://api.openai.com/v1")

    def llm_func(prompt, system_prompt=None, history_messages=[], **kwargs):
        return openai_complete_if_cache(
            "gpt-4o-mini",
            prompt,
            system_prompt=system_prompt,
            history_messages=history_messages,
            api_key=api_key,
            base_url=base_url,
            **kwargs,
        )

    # 3. Vision function (para processar imagens)
    def vision_func(prompt, system_prompt=None, history_messages=[], image_data=None, **kwargs):
        if image_data:
            return openai_complete_if_cache(
                "gpt-4o",  # Precisa de modelo com vision
                "",
                messages=[
                    {"role": "system", "content": system_prompt} if system_prompt else None,
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {
                                "type": "image_url",
                                "image_url": {"url": f"data:image/jpeg;base64,{image_data}"},
                            },
                        ],
                    },
                ],
                api_key=api_key,
                base_url=base_url,
                **kwargs,
            )
        else:
            return llm_func(prompt, system_prompt, history_messages, **kwargs)

    # 4. Embedding function
    embedding_func = EmbeddingFunc(
        embedding_dim=1536,  # text-embedding-3-small
        func=lambda texts: openai_embed(
            texts,
            model="text-embedding-3-small",
            api_key=api_key,
            base_url=base_url,
        ),
    )

    # 5. Inicializar RAG-Anything
    print("🚀 Inicializando RAG-Anything...")
    rag = RAGAnything(
        config=config,
        llm_model_func=llm_func,
        vision_model_func=vision_func,  # ← Isso permite processar imagens
        embedding_func=embedding_func,
    )

    # 6. Processar documento de teste
    # Você precisa de um PDF para testar
    # Coloque um PDF qualquer aqui ou passe via argumento
    import sys
    if len(sys.argv) < 2:
        print("❌ Uso: python test_simple.py <arquivo.pdf>")
        print("Exemplo: python test_simple.py documento.pdf")
        return

    file_path = sys.argv[1]
    print(f"📄 Processando: {file_path}")

    await rag.process_document_complete(
        file_path=file_path,
        output_dir="./output",
        parse_method="auto"  # MinerU detecta automaticamente
    )

    print("✅ Processamento completo!")

    # 7. Testar query
    print("\n🔍 Testando query...")
    result = await rag.aquery("Qual é o conteúdo principal deste documento?", mode="hybrid")
    print(f"\n📝 Resposta:\n{result}")

    # 8. Acessar LightRAG interno (opcional)
    print("\n🔗 Acessando LightRAG interno...")
    lightrag = rag.lightrag
    print(f"Working dir: {lightrag.working_dir}")
    print(f"Chunks processados: {len(lightrag.chunk_entity_relation_graph.get('chunks', []))}")

if __name__ == "__main__":
    asyncio.run(test_raganything())
```

**Testar:**

```bash
# Certifique-se que tem API key configurada
export OPENAI_API_KEY=sk-proj-xxxxx  # Sua chave OpenAI

# Ou se estiver usando .env do LightRAG
source /opt/lightrag/.env  # se tiver .env

# Teste com um PDF qualquer
python test_simple.py documento_teste.pdf
```

**O que você deve ver:**
```
🚀 Inicializando RAG-Anything...
📄 Processando: documento_teste.pdf
[MinerU] Parsing document...
[ImageProcessor] Processing 3 images...
[TableProcessor] Processing 2 tables...
✅ Processamento completo!

🔍 Testando query...
📝 Resposta:
O documento trata sobre [resposta baseada no conteúdo]...
```

---

## 🔧 Passo 3: Adicionar ao Servidor LightRAG

Agora que funciona standalone, vamos adicionar ao seu servidor atual.

### 3.1. Adicionar endpoint multimodal

Edite: `lightrag/api/routers/document_routes.py`

Adicione no topo (após os imports existentes):

```python
# No topo do arquivo, adicionar:
try:
    from raganything import RAGAnything, RAGAnythingConfig
    RAGANYTHING_AVAILABLE = True
except ImportError:
    RAGANYTHING_AVAILABLE = False
    logger.warning("RAG-Anything not installed. Multimodal processing disabled.")
```

Adicione novo endpoint (no final do arquivo, antes do `return router`):

```python
# Adicionar ANTES do `def create_document_routes(...)` retornar o router

if RAGANYTHING_AVAILABLE:
    @router.post("/upload_multimodal")
    async def upload_multimodal_document(
        file: UploadFile = File(...),
        background_tasks: BackgroundTasks = None,
        auth_context: Annotated[dict, Depends(combined_auth)] = None,
    ):
        """
        Upload and process document with multimodal RAG-Anything

        Handles images, tables, equations automatically.
        More expensive than normal upload but better for complex documents.
        """
        try:
            # 1. Salvar arquivo temporariamente
            temp_file = doc_manager.input_dir / f"{temp_prefix}{file.filename}"
            async with aiofiles.open(temp_file, "wb") as f:
                content = await file.read()
                await f.write(content)

            # 2. Configurar RAG-Anything
            config = RAGAnythingConfig(
                working_dir=rag.working_dir,
                enable_image_processing=True,
                enable_table_processing=True,
                enable_equation_processing=True,  # Pode desabilitar para economizar
            )

            # 3. Vision model function (usa GPT-4o)
            def vision_func(prompt, system_prompt=None, history_messages=[], image_data=None, **kwargs):
                if image_data:
                    return rag.llm_model_func(
                        "",
                        messages=[
                            {"role": "system", "content": system_prompt} if system_prompt else None,
                            {
                                "role": "user",
                                "content": [
                                    {"type": "text", "text": prompt},
                                    {
                                        "type": "image_url",
                                        "image_url": {"url": f"data:image/jpeg;base64,{image_data}"},
                                    },
                                ],
                            },
                        ],
                        **kwargs,
                    )
                else:
                    return rag.llm_model_func(prompt, system_prompt, history_messages, **kwargs)

            # 4. Criar instância RAG-Anything
            rag_anything = RAGAnything(
                config=config,
                llm_model_func=rag.llm_model_func,
                vision_model_func=vision_func,
                embedding_func=rag.embedding_func,
            )

            # 5. Processar documento
            output_dir = doc_manager.input_dir / "output"
            output_dir.mkdir(exist_ok=True)

            await rag_anything.process_document_complete(
                file_path=str(temp_file),
                output_dir=str(output_dir),
                parse_method="auto"
            )

            # 6. Remover arquivo temporário
            temp_file.unlink()

            # 7. Retornar sucesso
            return {
                "status": "success",
                "message": f"Document {file.filename} processed with multimodal RAG",
                "file_name": file.filename,
                "processing_type": "multimodal",
                "features_processed": {
                    "images": True,
                    "tables": True,
                    "equations": True,
                }
            }

        except Exception as e:
            logger.error(f"Multimodal upload failed: {str(e)}")
            raise HTTPException(status_code=500, detail=str(e))
else:
    logger.info("RAG-Anything endpoint disabled (package not installed)")
```

### 3.2. Adicionar variáveis de ambiente (opcional)

Edite `env.example` e adicione:

```bash
### RAG-Anything Configuration (optional)
# Enable multimodal document processing (requires raganything package)
# ENABLE_RAGANYTHING=true
# RAGANYTHING_ENABLE_IMAGES=true
# RAGANYTHING_ENABLE_TABLES=true
# RAGANYTHING_ENABLE_EQUATIONS=true
# RAGANYTHING_VISION_MODEL=gpt-4o  # Model for image processing
```

---

## 🎯 Passo 4: Usar via API

### Opção A: Upload Normal (LightRAG puro)

```bash
# Documentos simples (só texto)
curl -X POST "http://localhost:9621/documents/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@documento.pdf"
```

**Usa:** Processamento básico do LightRAG

---

### Opção B: Upload Multimodal (RAG-Anything)

```bash
# Documentos complexos (com imagens, tabelas)
curl -X POST "http://localhost:9621/documents/upload_multimodal" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@paper_cientifico.pdf"
```

**Usa:** Processamento avançado com RAG-Anything

---

### Via Python

```python
import requests

# Multimodal upload
with open("documento.pdf", "rb") as f:
    response = requests.post(
        "http://localhost:9621/documents/upload_multimodal",
        headers={"Authorization": "Bearer YOUR_TOKEN"},
        files={"file": f}
    )

print(response.json())
```

---

## 📊 Comparação Rápida

| Feature | `/upload` (normal) | `/upload_multimodal` |
|---------|-------------------|----------------------|
| **Processamento** | LightRAG básico | RAG-Anything avançado |
| **Imagens** | ❌ Ignora | ✅ Analisa (GPT-4o Vision) |
| **Tabelas** | ❌ Texto bruto | ✅ Estrutura completa |
| **Equações** | ❌ Ignora | ✅ Extrai LaTeX |
| **Custo** | Baixo | Alto (8-10x mais) |
| **Tempo** | Rápido (2-3 min) | Lento (10-15 min) |
| **Quando usar** | Docs simples | Papers, relatórios, manuais |

---

## ✅ Checklist de Instalação

- [ ] Python 3.10+ instalado ✅ (você tem 3.11.3)
- [ ] LightRAG funcionando ✅
- [ ] Instalar RAG-Anything: `pip install raganything`
- [ ] Testar standalone: `python test_simple.py documento.pdf`
- [ ] Adicionar endpoint no `document_routes.py`
- [ ] Reiniciar servidor LightRAG
- [ ] Testar upload via API
- [ ] Escolher quando usar cada endpoint

---

## 🐛 Troubleshooting

### 1. "ModuleNotFoundError: No module named 'raganything'"

```bash
pip install raganything
# ou
pip install 'raganything[all]'
```

---

### 2. "MinerU parsing failed"

```bash
pip install magic-pdf[full]
```

---

### 3. "Vision model required"

Certifique-se que está passando `vision_model_func` ao criar RAGAnything:

```python
rag_anything = RAGAnything(
    config=config,
    llm_model_func=llm_func,
    vision_model_func=vision_func,  # ← NÃO ESQUECER
    embedding_func=embedding_func,
)
```

---

### 4. Custo muito alto

**Solução 1: Desabilitar processamento de imagens**
```python
config = RAGAnythingConfig(
    enable_image_processing=False,  # ← Economiza MUITO
    enable_table_processing=True,
    enable_equation_processing=False,
)
```

**Solução 2: Processar seletivamente**
```python
# Só use /upload_multimodal quando realmente precisar
# Use /upload normal para documentos simples
```

---

### 5. "CUDA not available" (pode ignorar)

RAG-Anything tenta usar GPU se disponível, mas funciona sem:

```python
# Se der warning de CUDA, ignore ou:
# config = RAGAnythingConfig(..., device="cpu")
```

---

## 🎯 Decisão Rápida: Quando Usar?

**Use `/upload` (LightRAG normal) se:**
- ✅ Documento é só texto
- ✅ Não tem imagens importantes
- ✅ Quer rapidez e baixo custo

**Use `/upload_multimodal` (RAG-Anything) se:**
- ✅ Documento tem imagens/diagramas importantes
- ✅ Tem tabelas complexas
- ✅ Precisão é mais importante que custo
- ✅ É paper científico, manual técnico, relatório

---

## 🚀 Quick Start Commands

```bash
# 1. Instalar
pip install 'raganything[all]'

# 2. Testar
python test_simple.py seu_documento.pdf

# 3. Adicionar ao servidor
# (editar document_routes.py conforme acima)

# 4. Reiniciar servidor
docker compose -f docker-compose.full.yml restart lightrag

# 5. Testar API
curl -X POST "http://localhost:9621/documents/upload_multimodal" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@documento.pdf"
```

---

## 📚 Próximos Passos

1. ✅ Instalar RAG-Anything
2. ✅ Testar standalone
3. ✅ Adicionar endpoint ao servidor
4. ✅ Testar via API
5. 🎯 **Decidir quando usar cada tipo de upload**

---

**Dúvidas?**
- Arquivo de exemplo: `examples/raganything_example.py`
- Documentação: `RAGANYTHING_EXPLICACAO.md`
- Teste simples: Execute `test_simple.py` primeiro
