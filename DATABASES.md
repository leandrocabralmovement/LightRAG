# LightRAG com PostgreSQL + Neo4j (DozerDB)

Guia completo de como usar LightRAG com **PostgreSQL + pgvector** e **Neo4j (DozerDB)** para produção.

## 📚 Índice

1. [O que é cada banco de dados?](#o-que-é-cada-banco-de-dados)
2. [Arquitetura de Volumes](#arquitetura-de-volumes)
3. [Instalação Inicial](#instalação-inicial)
4. [Configuração de Ambiente](#configuração-de-ambiente)
5. [Iniciar os Serviços](#iniciar-os-serviços)
6. [Verificar Funcionamento](#verificar-funcionamento)
7. [Backup e Restore](#backup-e-restore)
8. [Troubleshooting](#troubleshooting)

---

## O que é cada banco de dados?

### PostgreSQL + pgvector
```
O QUÊ? → Banco de dados SQL com suporte a vetores
PARA QUÊ? → Armazena documentos, cache de LLM, embeddings (vetores)
DADOS IMPORTANTES? → SIM, perde dados se não fizer backup
```

**Exemplo de dados:**
- Documentos inseridos (LLM cache)
- Embeddings de textos (vetores)
- Status de processamento

### Neo4j (DozerDB)
```
O QUÊ? → Banco de dados de grafos
PARA QUÊ? → Armazena entidades e relações do conhecimento
DADOS IMPORTANTES? → SIM, perde dados se não fizer backup
```

**Exemplo de dados:**
- Entidades extraídas (pessoas, empresas, locais)
- Relações entre entidades
- Grafo de conhecimento

### LightRAG API
```
O QUÊ? → Aplicação Python que conecta aos dois bancos
PARA QUÊ? → Orquestra inserção, busca e geração de respostas
```

---

## Arquitetura de Volumes

**IMPORTANTE:** Volumes são **PERSISTENT**, dados NÃO são perdidos!

```
VPS Hetzner
└── /opt/lightrag/
    ├── docker-compose.full.yml (config)
    ├── .env (senhas)
    ├── data/ (VOLUMES - DADOS IMPORTANTES!)
    │   ├── postgres/  ← PostgreSQL armazena aqui
    │   ├── neo4j/     ← Neo4j armazena aqui
    │   ├── rag_storage/  ← Cache do LightRAG
    │   ├── inputs/    ← Documentos enviados
    │   └── tiktoken/  ← Cache de tokenização
    └── logs/
        └── neo4j/     ← Logs do Neo4j
```

### Como funciona a persistência?

1. **Volume = Pasta no Disco**
   ```
   Volume "postgres-data" = Pasta /opt/lightrag/data/postgres
   Volume "neo4j-data" = Pasta /opt/lightrag/data/neo4j
   ```

2. **Container compartilha a Pasta**
   ```
   Quando container morre → Pasta continua existindo
   Quando container reinicia → Pasta é reatachada
   Dados = SALVOS!
   ```

3. **Diagrama:**
   ```
   Container PostgreSQL         /opt/lightrag/data/postgres
   (morre aqui)           ←→     (dados vivos aqui!)

   Container Neo4j              /opt/lightrag/data/neo4j
   (morre aqui)           ←→     (dados vivos aqui!)
   ```

---

## Instalação Inicial

### Passo 1: Preparar Diretórios

```bash
# SSH na VPS
ssh root@116.203.193.178

# Criar estrutura de pastas
mkdir -p /opt/lightrag/data/{postgres,neo4j,rag_storage,inputs,tiktoken}
mkdir -p /opt/lightrag/logs/neo4j

# Definir permissões
chmod -R 755 /opt/lightrag/data
chmod -R 755 /opt/lightrag/logs
```

### Passo 2: Clonar Repositório

```bash
cd /opt
git clone https://github.com/seu_username/LightRAG.git lightrag
cd lightrag
```

### Passo 3: Copiar Ambiente

```bash
# Copiar do exemplo
cp .env.production.example .env

# Editar com suas configurações
nano .env
```

**IMPORTANTE: Mudar as senhas padrão!**

```bash
# Edite estas linhas no .env:
POSTGRES_PASSWORD=sua_senha_postgres_segura_aqui_123!
NEO4J_PASSWORD=sua_senha_neo4j_segura_aqui_456!
OPENAI_API_KEY=sk-seu_api_key_aqui
AUTH_ACCOUNTS=admin:sua_senha_admin_segura_aqui
```

### Passo 4: Fazer Executável

```bash
chmod +x /opt/lightrag/backup.sh
chmod +x /opt/lightrag/restore.sh
chmod +x /opt/lightrag/deploy.sh
```

---

## Configuração de Ambiente

### Arquivo `.env` - Seções Importantes

```bash
# ===== POSTGRESQL (BANCO 1) =====
POSTGRES_CONNECTION_STRING=postgresql://lightrag:sua_senha@postgres:5432/lightrag
POSTGRES_PASSWORD=sua_senha_postgres_aqui
POSTGRES_PORT=5432

# ===== NEO4J (BANCO 2) =====
NEO4J_URI=neo4j://neo4j:7687
NEO4J_PASSWORD=sua_senha_neo4j_aqui
NEO4J_PORT=7687

# ===== STORAGE ENGINES (QUAL BANCO USAR) =====
KV_STORAGE=PGKVStorage              # Usa PostgreSQL
VECTOR_STORAGE=PGVectorStorage      # Usa PostgreSQL
GRAPH_STORAGE=Neo4JStorage          # Usa Neo4j
DOC_STATUS_STORAGE=PGDocStatusStorage  # Usa PostgreSQL

# ===== LLM (SEU PROVIDER) =====
OPENAI_API_KEY=sk-...
# OU
# OLLAMA_BASE_URL=http://ollama:11434

# ===== ADMIN =====
AUTH_ACCOUNTS=admin:sua_senha_admin_aqui
TOKEN_SECRET=uma_chave_secreta_aleatoria_bem_longa
```

### Checklist de Configuração

- [ ] `POSTGRES_PASSWORD` mudada (não use padrão!)
- [ ] `NEO4J_PASSWORD` mudada (não use padrão!)
- [ ] `OPENAI_API_KEY` configurada
- [ ] `AUTH_ACCOUNTS` com senha forte
- [ ] `TOKEN_SECRET` com valor aleatório
- [ ] `DATA_MOUNT_PATH=/opt/lightrag`

---

## Iniciar os Serviços

### Opção 1: Tudo junto (recomendado)

```bash
cd /opt/lightrag

# Inicia PostgreSQL, Neo4j e LightRAG
docker-compose -f docker-compose.full.yml up -d --build
```

Isso vai:
1. Criar pastas de dados em `/opt/lightrag/data/`
2. Criar volumes Docker
3. Iniciar PostgreSQL
4. Iniciar Neo4j
5. Iniciar LightRAG
6. LightRAG espera PostgreSQL e Neo4j ficar prontos

**Tempo de espera:** 2-3 minutos (primeira vez)

### Opção 2: Um por um (debugging)

```bash
# Apenas PostgreSQL
docker-compose -f docker-compose.full.yml up -d postgres

# Esperando ficar pronto (quando ver "listening on" nos logs)
docker-compose logs postgres

# Então Neo4j
docker-compose -f docker-compose.full.yml up -d neo4j
docker-compose logs neo4j

# Enfim LightRAG
docker-compose -f docker-compose.full.yml up -d lightrag
docker-compose logs lightrag
```

---

## Verificar Funcionamento

### 1. Containers Rodando

```bash
docker ps

# Esperado:
# lightrag         (porta 9621)
# lightrag-postgres
# lightrag-neo4j
```

### 2. Verificar Logs

```bash
# Todos os logs
docker-compose -f docker-compose.full.yml logs

# Apenas um serviço
docker-compose logs postgres
docker-compose logs neo4j
docker-compose logs lightrag

# Tempo real (segue logs)
docker-compose logs -f lightrag
```

### 3. Testar Conexões

**PostgreSQL:**
```bash
docker exec lightrag-postgres psql -U lightrag -d lightrag -c "SELECT 1"
```

**Neo4j (Browser):**
```
Abrir navegador: http://116.203.193.178:7474
Login: neo4j
Senha: (a que configurou em .env)
```

**LightRAG API:**
```bash
curl http://localhost:9621/health
```

### 4. Verificar Volumes (Dados)

```bash
# Ver tamanho dos dados
du -sh /opt/lightrag/data/

# Ver arquivos
ls -la /opt/lightrag/data/postgres/
ls -la /opt/lightrag/data/neo4j/
```

---

## Backup e Restore

### ⚠️ SUPER IMPORTANTE

Sempre que fizer uma alteração significativa ou antes de atualizar, faça backup!

### Backup Automático

```bash
# Fazer backup agora
bash /opt/lightrag/backup.sh

# Backup vai para: ./backups/2024-01-15_10-30-45/
```

**O que é feito:**
```
✓ Dump completo do PostgreSQL
✓ Cópia completa do Neo4j
✓ Cópia dos dados do LightRAG
✓ Cópia dos documentos inseridos
✓ Arquivo comprimido (.tar.gz)
```

### Agendar Backup Automático (Crontab)

```bash
# Editar crontab
crontab -e

# Adicionar estas linhas:

# Backup diário às 2 da manhã
0 2 * * * /opt/lightrag/backup.sh /backups/daily

# Backup semanal (domingo às 3 da manhã)
0 3 * * 0 /opt/lightrag/backup.sh /backups/weekly

# Backup mensal (1º dia às 4 da manhã)
0 4 1 * * /opt/lightrag/backup.sh /backups/monthly
```

### Restore (Recuperar do Backup)

**Cenário:** Database corrompeu, precisa restaurar

```bash
# 1. Parar serviços
docker-compose down

# 2. Restaurar
bash /opt/lightrag/restore.sh /backups/2024-01-15_10-30-45

# 3. Confirmar operação (vai pedir yes/no)
# 4. Seguir instruções
# 5. Containers serão reiniciados automaticamente
```

**⚠️ AVISO:** Restore deleta dados atuais e restaura os antigos!

---

## Troubleshooting

### Container não inicia

```bash
# Ver erro
docker-compose logs postgres
docker-compose logs neo4j
docker-compose logs lightrag

# Causa comum: senha errada no .env
# Solução: editar .env e reiniciar
```

### Sem espaço em disco

```bash
# Ver uso
df -h

# Limpar Docker
docker system prune -a

# Ou listar tamanho dos dados
du -sh /opt/lightrag/data/*
```

### Neo4j não conecta

```bash
# Verificar se está pronto
docker-compose logs neo4j | grep "started"

# Health check
docker inspect lightrag-neo4j | grep -A 5 Health

# Esperar mais tempo (pode levar 30+ segundos)
sleep 60 && docker-compose up -d lightrag
```

### PostgreSQL lento

```bash
# Aumentar recursos no docker-compose.full.yml
# Aumentar shared_buffers

# Ou ver queries lentas
docker exec lightrag-postgres psql -U lightrag -d lightrag \
  -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

### Dados desapareceram

```bash
# Verificar se volume ainda existe
docker volume ls | grep postgres
docker volume ls | grep neo4j

# Verificar pastas
ls -la /opt/lightrag/data/postgres/
ls -la /opt/lightrag/data/neo4j/

# Se a pasta existe, restaurar do backup
bash /opt/lightrag/restore.sh /backups/ultima_data_aqui
```

---

## Operações Comuns

### Reiniciar tudo

```bash
docker-compose -f docker-compose.full.yml restart
```

### Parar (sem perder dados)

```bash
docker-compose -f docker-compose.full.yml stop
```

### Remover containers (dados continuam salvos)

```bash
docker-compose -f docker-compose.full.yml down

# Dados estão aqui:
ls -la /opt/lightrag/data/
```

### Remover TUDO (cuidado!)

```bash
# Apenas containers (dados não são deletados)
docker-compose down

# Com volumes (DELETA DADOS!)
docker-compose down -v
```

### Atualizar código e rebuild

```bash
# Pull código novo
cd /opt/lightrag
git pull origin main

# Rebuild e restart
docker-compose -f docker-compose.full.yml up -d --build
```

---

## Senhas e Segurança

### Onde estão as senhas?

```bash
# Arquivo .env (NÃO commitar no git!)
POSTGRES_PASSWORD=xxx
NEO4J_PASSWORD=xxx
OPENAI_API_KEY=xxx
TOKEN_SECRET=xxx
```

### Como gerar senhas fortes

```bash
# Usando openssl
openssl rand -base64 32

# Exemplo output:
# GkL9xQ2mP8vZ4nW5rL7hJ3bV9tK2dF6gM
```

### Mudança de senhas (em produção)

**⚠️ Cuidado:** Isso reinicia os bancos!

```bash
# 1. Fazer backup primeiro
bash /opt/lightrag/backup.sh

# 2. Parar tudo
docker-compose down

# 3. Deletar volumes (vai perder dados!)
docker volume rm lightrag_postgres-data lightrag_neo4j-data

# 4. Editar .env com novas senhas
nano .env

# 5. Iniciar (vai recriar com novas senhas)
docker-compose -f docker-compose.full.yml up -d
```

---

## Performance

### Otimizações Padrão

O `docker-compose.full.yml` já vem otimizado com:

```yaml
PostgreSQL:
  - shared_buffers: 256MB
  - effective_cache_size: 1GB
  - work_mem: 16MB

Neo4j:
  - heap: 1G a 2G
  - pagecache: 1GB

LightRAG:
  - CPU limit: 2 cores
  - Memory: 4GB
```

### Se servidor for maior

Edite `docker-compose.full.yml`:

```yaml
lightrag:
  deploy:
    resources:
      limits:
        cpus: '4'  # Aumentar
        memory: 8G # Aumentar
```

---

## Monitoramento

### Ver uso de recursos

```bash
docker stats

# Mostra: CPU%, MEMORY, Network I/O
```

### Ver tamanho dos bancos

```bash
# PostgreSQL
docker exec lightrag-postgres du -sh /var/lib/postgresql/data

# Neo4j
du -sh /opt/lightrag/data/neo4j

# Tudo
du -sh /opt/lightrag/data/*
```

---

## Dúvidas Frequentes

**P: Perco dados quando atualizo o código?**
A: Não! Os volumes persistem. Dados estão em `/opt/lightrag/data/`

**P: Quanto espaço em disco preciso?**
A: Depende de quanto você armazenar. Comece com 50GB, aumente conforme necessário.

**P: Como faço restore de um backup?**
A: `bash /opt/lightrag/restore.sh /caminho/do/backup`

**P: Posso acessar Neo4j via navegador?**
A: Sim! `http://116.203.193.178:7474` (porta 7474)

**P: Posso acessar PostgreSQL remotamente?**
A: Sim, na porta 5432 (mas restrinja por firewall por segurança)

**P: O que faz o arquivo `init-postgres/init-lightrag.sql`?**
A: Cria a extensão pgvector automaticamente quando PostgreSQL inicia

**P: Preciso atualizar as senhas?**
A: Sim, altere todas as senhas padrão antes de produção

---

## Recursos

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **pgvector Documentation**: https://github.com/pgvector/pgvector
- **Neo4j Documentation**: https://neo4j.com/docs/
- **Docker Volumes**: https://docs.docker.com/storage/volumes/

---

**Última atualização:** 7 de Novembro de 2025
**Versão:** 1.0.0
