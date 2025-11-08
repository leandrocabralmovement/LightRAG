# 🗄️ LightRAG com Banco de Dados - Guia de Início Rápido

Você clonou o repositório e quer instalar **PostgreSQL + Neo4j** com LightRAG?

**Leia este arquivo PRIMEIRO.** Depois escolha qual guia usar.

---

## 📊 Arquivos Criados (Este Projeto)

```
.
├── docker-compose.full.yml          ← USE ESTE (todo em um)
├── .env.production.example           ← Copie para .env (configure senhas)
├── init-postgres/
│   └── init-lightrag.sql            ← Setup automático PostgreSQL
├── backup.sh                         ← Fazer backup dos dados
├── restore.sh                        ← Restaurar do backup
├── SETUP_DATABASES_SIMPLES.md        ← 👈 LEIA PRIMEIRO (noob)
├── DATABASES.md                      ← Detalhes técnicos
└── README_DATABASES.md               ← Este arquivo
```

---

## 🎯 Qual Guia Devo Ler?

### Sou NOOB / Quero algo rápido
👉 **Leia: `SETUP_DATABASES_SIMPLES.md`** (5 minutos)
- Passo-a-passo super simples
- Sem detalhes técnicos
- Leva você do 0 ao funcionando

### Quero entender tudo
👉 **Leia: `DATABASES.md`** (30 minutos)
- Explica cada banco de dados
- Como funcionam volumes
- Troubleshooting completo
- Boas práticas

### Quero só copiar e colar
👉 **Copie de: `SETUP_DATABASES_SIMPLES.md`**
- Tem todos os comandos prontos
- Só copia e cola

---

## ⚡ TL;DR (Muito Resumido)

```bash
# 1. SSH
ssh root@116.203.193.178

# 2. Crie pastas
mkdir -p /opt/lightrag/data/{postgres,neo4j,rag_storage,inputs,tiktoken}

# 3. Clone
cd /opt && git clone https://github.com/seu_username/LightRAG.git lightrag

# 4. Configure
cd lightrag && cp .env.production.example .env && nano .env
# Mude: POSTGRES_PASSWORD, NEO4J_PASSWORD, OPENAI_API_KEY

# 5. Inicie
docker-compose -f docker-compose.full.yml up -d --build

# 6. Aguarde 3 minutos

# 7. Acesse
# Abra: http://116.203.193.178:9621
```

---

## 📚 O Que Cada Arquivo Faz

### `docker-compose.full.yml`
```
Arquivo principal que descreve:
- Container PostgreSQL (banco de dados)
- Container Neo4j (grafo)
- Container LightRAG (seu app)
- Volumes (pastas que guardam dados)
- Networks (como os containers se comunicam)
```

**Usar com:**
```bash
docker-compose -f docker-compose.full.yml up -d
```

### `.env.production.example`
```
Arquivo de configuração exemplo.
Tem TODAS as opções possíveis.

Use como template:
cp .env.production.example .env
```

**⚠️ IMPORTANTE:**
- NUNCA commitar `.env` no git
- Mude as senhas padrão

### `init-postgres/init-lightrag.sql`
```
Script SQL que roda automáticamente quando PostgreSQL inicia.

O que faz:
- Cria extensão pgvector (para vetores)
- Cria função para atualizar timestamps
- Setup básico
```

**Automático.** Você não faz nada.

### `backup.sh`
```
Faz backup de TUDO:
- Dump PostgreSQL
- Arquivos Neo4j
- Dados LightRAG
- Inputs (documentos)
```

**Usar:**
```bash
bash backup.sh
# Cria pasta: ./backups/2024-01-15_10-30-45/
```

### `restore.sh`
```
Restaura dados de um backup anterior.

⚠️ CUIDADO:
- Deleta dados atuais
- Restaura os antigos
```

**Usar:**
```bash
bash restore.sh ./backups/2024-01-15_10-30-45/
```

---

## 🏗️ Arquitetura

```
Seu Computador
    ↓
    ↓ SSH
    ↓
VPS Hetzner (116.203.193.178)
│
├── Docker Engine
│   │
│   ├── 📦 PostgreSQL Container
│   │   └── 📁 /opt/lightrag/data/postgres/ (dados persiste)
│   │
│   ├── 🔗 Neo4j Container
│   │   └── 📁 /opt/lightrag/data/neo4j/ (dados persiste)
│   │
│   └── 🚀 LightRAG Container (porta 9621)
│       ├── Conecta ao PostgreSQL
│       ├── Conecta ao Neo4j
│       └── 📁 /opt/lightrag/data/rag_storage/ (dados)
│
└── Disco (HD/SSD)
    └── 📁 /opt/lightrag/data/ (DADOS SEGUROS AQUI!)
        ├── postgres/
        ├── neo4j/
        ├── rag_storage/
        ├── inputs/
        └── tiktoken/
```

### Como Funciona Persistência

**Sem Volumes (❌ perde dados):**
```
Container morre → Todos os dados deletam
```

**Com Volumes (✅ salva dados):**
```
Container PostgreSQL         /opt/lightrag/data/postgres/
     ↓                            ↑
     ←──────────  Volume  ────────
Dados salvos!
```

Quando container morre, pasta continua. Quando container reinicia, é reconnectado à pasta = **dados salvos!**

---

## 🔑 Senhas e Segurança

Você vai configurar 3 senhas no `.env`:

```bash
# Senha do PostgreSQL
POSTGRES_PASSWORD=escolha_uma_senha_forte_aqui_123!

# Senha do Neo4j
NEO4J_PASSWORD=escolha_outra_senha_forte_aqui_456!

# Usuário admin do LightRAG
AUTH_ACCOUNTS=admin:escolha_outra_senha_aqui_789!
```

**⚠️ IMPORTANTE:**
1. Nunca deixe as senhas padrão
2. Use senhas diferentes para cada serviço
3. Não coloque o `.env` no git
4. Guarde as senhas em local seguro

**Gerar senha aleatória:**
```bash
openssl rand -base64 32
# Output: GkL9xQ2mP8vZ4nW5rL7hJ3bV9tK2dF6gM
```

---

## 📱 Como Acessar

### LightRAG Web UI
```
http://116.203.193.178:9621
```

Login:
- Usuário: `admin`
- Senha: (a que configurou)

### Neo4j Browser
```
http://116.203.193.178:7474
```

Login:
- Usuário: `neo4j`
- Senha: (a que configurou em NEO4J_PASSWORD)

### PostgreSQL (via terminal)
```bash
docker exec lightrag-postgres psql -U lightrag -d lightrag
```

---

## 🛠️ Comandos Úteis

### Ver containers
```bash
docker ps
```

### Ver logs
```bash
docker-compose logs lightrag          # Logs do LightRAG
docker-compose logs postgres          # Logs do PostgreSQL
docker-compose logs neo4j             # Logs do Neo4j
docker-compose logs -f lightrag       # Tempo real
```

### Parar (sem perder dados)
```bash
docker-compose stop
```

### Iniciar novamente
```bash
docker-compose start
```

### Atualizar código e rebuild
```bash
git pull origin main
docker-compose -f docker-compose.full.yml up -d --build
```

### Fazer backup
```bash
bash backup.sh
```

### Restaurar backup
```bash
bash restore.sh ./backups/2024-01-15_10-30-45/
```

### Remover tudo (⚠️ cuidado!)
```bash
docker-compose down -v  # -v deleta volumes também
```

---

## 📍 Checklist de Setup

- [ ] SSH na VPS
- [ ] Criou pastas em `/opt/lightrag/data/`
- [ ] Clonou repositório
- [ ] Copiou `.env.production.example` para `.env`
- [ ] Editou `.env` (mudou senhas)
- [ ] Rodou `docker-compose -f docker-compose.full.yml up -d --build`
- [ ] Aguardou 3 minutos
- [ ] Verificou com `docker ps` (3 containers rodando)
- [ ] Acessou `http://116.203.193.178:9621`
- [ ] Fez login com admin
- [ ] Fez primeiro backup: `bash backup.sh`

---

## 🐛 Se Algo Der Erro

### Container não inicia
```bash
docker-compose logs CONTAINER_NAME
# Leia a mensagem de erro
```

### PostgreSQL recusa conexão
```bash
# Esperar mais um pouco (pode levar até 30 segundos)
sleep 60
docker-compose up -d lightrag
```

### Neo4j não conecta
```bash
# Verificar se está pronto
docker logs lightrag-neo4j | grep "started"

# Restart Neo4j
docker-compose restart neo4j
```

### Sem espaço em disco
```bash
# Ver uso
df -h

# Limpar Docker (remove imagens não usadas)
docker system prune -a
```

### Dados desapareceram
```bash
# Backup ainda existe?
ls -la ./backups/

# Restaurar
bash restore.sh ./backups/ultima_data_aqui/
```

---

## 🚀 Próximas Ações

1. **Teste o setup**
   - Acesse `http://116.203.193.178:9621`
   - Faça login
   - Teste upload de documento

2. **Configure deploy automático**
   - Leia: `DEPLOYMENT_QUICK_START.md`
   - Setup GitHub SSH keys
   - Próximas atualizações serão automáticas

3. **Configure seu LLM**
   - OpenAI, Ollama, Gemini, etc
   - Edite `.env`
   - Restart: `docker-compose restart lightrag`

4. **Faça backups regularmente**
   - Diário: `bash backup.sh`
   - Ou configure crontab para automático

5. **Monitore a saúde**
   - Ver logs: `docker-compose logs`
   - Espaço em disco: `df -h`
   - Tamanho dos dados: `du -sh /opt/lightrag/data/`

---

## 📚 Documentação por Tópico

| Tópico | Arquivo |
|--------|---------|
| Setup para noob | `SETUP_DATABASES_SIMPLES.md` |
| Detalhes técnicos | `DATABASES.md` |
| Deploy automático | `DEPLOYMENT_QUICK_START.md` |
| Deploy completo | `DEPLOYMENT.md` |
| Troubleshooting | `DEPLOYMENT.md` (seção 9) |

---

## 💬 Precisa de Ajuda?

1. **Cheque os logs**
   ```bash
   docker-compose logs
   ```

2. **Leia DATABASES.md**
   - Seção "Troubleshooting"

3. **Comunidade LightRAG**
   - Discord: https://discord.gg/yF2MmDJyGJ
   - Issues: https://github.com/HKUDS/LightRAG/issues

4. **Docker/PostgreSQL/Neo4j docs**
   - PostgreSQL: https://www.postgresql.org/docs/
   - Neo4j: https://neo4j.com/docs/
   - Docker: https://docs.docker.com/

---

## ✅ Resumo

Você agora tem:

✅ **PostgreSQL** - Guarda documentos e vetores
✅ **Neo4j** - Guarda entidades e relações
✅ **LightRAG** - Conecta aos dois
✅ **Backup** - Scripts prontos para backup/restore
✅ **Persistência** - Dados nunca são perdidos
✅ **Documentação** - Guias completos

**Tempo total de setup:** ~30 minutos
**Depois funcionará sempre:** ∞

---

**Boa sorte! Qualquer dúvida, releia este arquivo ou veja SETUP_DATABASES_SIMPLES.md** 🚀
