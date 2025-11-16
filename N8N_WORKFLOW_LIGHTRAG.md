# 🤖 N8N Workflow - Chat com Upload de Arquivo + LightRAG

## 🎯 O que vamos fazer:

1. Chat com usuário (permite upload de arquivo)
2. Detectar se foi enviado arquivo
3. Fazer upload multimodal pro LightRAG
4. Fazer query com a pergunta do usuário
5. Retornar resposta

---

## 📋 WORKFLOW COMPLETO

### Estrutura:

```
1. Chat Trigger (webhook ou interface)
   ↓
2. IF (tem arquivo?)
   ├─ SIM → Upload Multimodal
   │         ↓
   │         Query com arquivo processado
   │         ↓
   │         Resposta
   │
   └─ NÃO → Query direta
             ↓
             Resposta
```

---

## 🔧 CONFIGURAÇÃO PASSO A PASSO

### Node 1: Chat Trigger

**Opção A: Webhook Chat**
```
Node: Webhook
Method: POST
Path: /chat
Body:
  - message: string (mensagem do usuário)
  - file: binary (opcional - arquivo)
```

**Opção B: @n8n/n8n-nodes-langchain - Chat**
```
Node: Chat Trigger
Enable file uploads: ✅ TRUE
```

---

### Node 2: IF - Verificar se tem arquivo

```
Node: IF
Conditions:
  - {{ $json.file }} is not empty
  OR
  - {{ $binary.data }} exists
```

---

### Node 3A: Upload Multimodal (SE tem arquivo)

```
Node: HTTP Request
Method: POST
URL: http://116.203.193.178:9621/documents/upload_multimodal

Authentication: None (ou Bearer Token se configurou)

Send Body: Yes
Body Content Type: Form-Data / Multipart

Body Parameters:
  Name: file
  Type: Binary Data
  Input Binary Field: data (ou o nome do campo com arquivo)
```

**Configuração detalhada:**
```json
{
  "url": "http://116.203.193.178:9621/documents/upload_multimodal",
  "method": "POST",
  "sendBody": true,
  "contentType": "multipart-form-data",
  "bodyParameters": {
    "parameters": [
      {
        "name": "file",
        "value": "",
        "parameterType": "formBinaryData",
        "inputDataFieldName": "data"
      }
    ]
  }
}
```

**Response esperado:**
```json
{
  "status": "success",
  "file_name": "documento.pdf",
  "processing_type": "multimodal_direct",
  "statistics": {
    "total_blocks": 307,
    "text_blocks": 211,
    "tables_processed": 20
  }
}
```

---

### Node 3B: Set Variables (extrair info do upload)

```
Node: Set
Values:
  - filename: {{ $json.file_name }}
  - uploaded: true
```

---

### Node 4: Query LightRAG

```
Node: HTTP Request
Method: POST
URL: http://116.203.193.178:9621/query

Headers:
  Content-Type: application/json

Body (JSON):
{
  "query": "{{ $('Chat Trigger').item.json.message }}",
  "mode": "hybrid",
  "top_k": 40,
  "chunk_top_k": 20
}
```

**Response esperado:**
```json
{
  "response": "Com base no documento...",
  "references": [
    {
      "reference_id": "1",
      "file_path": "documento.pdf"
    }
  ]
}
```

---

### Node 5: Format Response

```
Node: Code (JavaScript)
Code:
```

```javascript
const response = $input.item.json.response;
const references = $input.item.json.references || [];
const uploaded = $('Set').item.json.uploaded || false;

let message = response;

// Se foi upload novo, adicionar mensagem
if (uploaded) {
  const filename = $('Set').item.json.filename;
  message = `✅ Documento "${filename}" processado com sucesso!\n\n${response}`;
}

// Adicionar referências
if (references.length > 0) {
  message += "\n\n📚 Fontes:\n";
  references.forEach(ref => {
    message += `- ${ref.file_path}\n`;
  });
}

return {
  json: {
    message: message,
    references: references
  }
};
```

---

### Node 6: Respond to User

```
Node: Respond to Webhook / Chat
Message: {{ $json.message }}
```

---

## 🎨 WORKFLOW VISUAL (JSON completo)

Copie e cole no N8N:

```json
{
  "name": "LightRAG Chat com Upload",
  "nodes": [
    {
      "parameters": {
        "path": "chat",
        "options": {}
      },
      "id": "webhook1",
      "name": "Chat Trigger",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $binary.data }}",
              "operation": "isNotEmpty"
            }
          ]
        }
      },
      "id": "if1",
      "name": "Has File?",
      "type": "n8n-nodes-base.if",
      "position": [450, 300]
    },
    {
      "parameters": {
        "url": "http://116.203.193.178:9621/documents/upload_multimodal",
        "method": "POST",
        "sendBody": true,
        "contentType": "multipart-form-data",
        "bodyParameters": {
          "parameters": [
            {
              "name": "file",
              "parameterType": "formBinaryData",
              "inputDataFieldName": "data"
            }
          ]
        }
      },
      "id": "upload1",
      "name": "Upload Multimodal",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 200]
    },
    {
      "parameters": {
        "url": "http://116.203.193.178:9621/query",
        "method": "POST",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $('Chat Trigger').item.json.message }}"
            },
            {
              "name": "mode",
              "value": "hybrid"
            },
            {
              "name": "top_k",
              "value": 40
            }
          ]
        }
      },
      "id": "query1",
      "name": "Query LightRAG",
      "type": "n8n-nodes-base.httpRequest",
      "position": [850, 300]
    },
    {
      "parameters": {
        "jsCode": "const response = $input.item.json.response;\nconst refs = $input.item.json.references || [];\n\nlet msg = response;\n\nif (refs.length > 0) {\n  msg += '\\n\\n📚 Fontes:\\n';\n  refs.forEach(r => msg += `- ${r.file_path}\\n`);\n}\n\nreturn { json: { message: msg } };"
      },
      "id": "code1",
      "name": "Format Response",
      "type": "n8n-nodes-base.code",
      "position": [1050, 300]
    }
  ],
  "connections": {
    "Chat Trigger": {
      "main": [[{ "node": "Has File?", "type": "main", "index": 0 }]]
    },
    "Has File?": {
      "main": [
        [{ "node": "Upload Multimodal", "type": "main", "index": 0 }],
        [{ "node": "Query LightRAG", "type": "main", "index": 0 }]
      ]
    },
    "Upload Multimodal": {
      "main": [[{ "node": "Query LightRAG", "type": "main", "index": 0 }]]
    },
    "Query LightRAG": {
      "main": [[{ "node": "Format Response", "type": "main", "index": 0 }]]
    }
  }
}
```

---

## 🧪 TESTE SIMPLES (sem workflow)

**Teste direto via cURL primeiro:**

```bash
# Upload arquivo
curl -X POST "http://116.203.193.178:9621/documents/upload_multimodal" \
  -F "file=@seu_arquivo.pdf"

# Query
curl -X POST "http://116.203.193.178:9621/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "sua pergunta aqui",
    "mode": "hybrid",
    "top_k": 40
  }'
```

---

## 📊 WORKFLOW ALTERNATIVO (Mais Simples)

Se não precisa de chat interativo:

```
1. Manual Trigger
   ↓
2. Read Binary Files (ler PDFs de uma pasta)
   ↓
3. Loop over Files
   ├─ Upload Multimodal
   └─ Log resultado
```

---

## 🔥 EXEMPLO PRÁTICO - Agent LangChain + LightRAG

Se você usa LangChain Agent no N8N:

```
1. Agent (LangChain)
   ├─ Tool 1: Upload Document
   │   → HTTP Request to /documents/upload_multimodal
   │
   └─ Tool 2: Query LightRAG
       → HTTP Request to /query
```

---

**Qual abordagem você prefere?**

1. Workflow completo com chat?
2. Workflow simples (upload + query)?
3. Integração com Agent LangChain?

Me diz que eu monto pro seu caso! 🚀
