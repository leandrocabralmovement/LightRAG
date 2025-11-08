# Setup PostgreSQL + Neo4j com LightRAG - Guia Noob

Instruções SUPER simples, passo-a-passo.

---

## Resumo

Você vai instalar **3 coisas juntas**:

1. **PostgreSQL** - Banco de dados que guarda documentos e vetores
2. **Neo4j** - Banco de dados que guarda relacionamentos
3. **LightRAG** - Seu aplicativo que usa os 2 bancos

**Dados nunca são perdidos** porque ficam em pastas do disco!

---

## Passo-a-Passo

### 1️⃣ SSH na VPS

```bash
ssh root@116.203.193.178
```

### 2️⃣ Crie as pastas

Estas pastas vão guardar os DADOS (nunca perdem):

```bash
mkdir -p /opt/lightrag/data/{postgres,neo4j,rag_storage,inputs,tiktoken}
mkdir -p /opt/lightrag/logs/neo4j
```

### 3️⃣ Clone seu repositório

```bash
cd /opt
git clone https://github.com/SEU_USERNAME/LightRAG.git lightrag
cd lightrag
```

### 4️⃣ Copie o arquivo de configuração

```bash
cp .env.production.example .env
```

### 5️⃣ **IMPORTANTE:** Edite o `.env`

```bash
nano .env
```

Procure e mude ESTAS linhas (press Ctrl+W para buscar):

```bash
# Linha 227: Mude a senha do PostgreSQL
POSTGRES_PASSWORD=lightrag_secure_password_change_me
⬇️
POSTGRES_PASSWORD=sua_senha_super_segura_postgres_123!

# Linha 237: Mude a senha do Neo4j
NEO4J_PASSWORD=neo4j_secure_password_change_me
⬇️
NEO4J_PASSWORD=sua_senha_super_segura_neo4j_456!

# Procure e coloque sua chave OpenAI (se tiver):
OPENAI_API_KEY=sk-...
```

**Como salvar:** Press `Ctrl+X`, depois `Y`, depois `Enter`

### 6️⃣ Inicie os serviços

```bash
docker-compose -f docker-compose.full.yml up -d --build
```

**Isso vai:**
- ✅ Baixar imagens Docker
- ✅ Criar containers
- ✅ Iniciar PostgreSQL (espera 10 segundos)
- ✅ Iniciar Neo4j (espera 20 segundos)
- ✅ Iniciar LightRAG (espera 10 segundos)

**Tempo total:** 2-3 minutos

### 7️⃣ Espere e verifique

```bash
# Aguarde 3 minutos, depois verifique:
docker ps

# Deve mostrar 3 containers rodando:
# - lightrag
# - lightrag-postgres
# - lightrag-neo4j
```

### 8️⃣ Acesse seu app

Abra o navegador:
```
http://116.203.193.178:9621
```

Login com:
- Usuário: `admin`
- Senha: (a que configurou em `AUTH_ACCOUNTS` no .env)

✅ **PRONTO!**

---

## ❓ Dúvidas Comuns

**P: E se der erro?**
```bash
# Ver os erros
docker-compose logs lightrag
```

**P: Quero parar tudo sem perder dados?**
```bash
docker-compose stop
# Dados estão seguros em /opt/lightrag/data/
```

**P: Quero iniciar novamente?**
```bash
docker-compose start
```

**P: Quero ver os logs em tempo real?**
```bash
docker-compose logs -f lightrag
```

**P: Quero fazer backup dos dados?**
```bash
bash /opt/lightrag/backup.sh
# Backup vai para ./backups/
```

**P: Preciso restaurar um backup?**
```bash
bash /opt/lightrag/restore.sh ./backups/2024-01-15_10-30-45
```

---

## 🔒 Senhas - Não Esqueça!

No `.env` você configurou 3 senhas:

```
POSTGRES_PASSWORD = senha do banco PostgreSQL
NEO4J_PASSWORD = senha do banco Neo4j
AUTH_ACCOUNTS = senha do seu usuário admin
```

**⚠️ IMPORTANTE:**
- Nunca compartilhe estas senhas
- Nunca faça commit do `.env` no git
- Troque as senhas padrão (não deixe como exemplo)

---

## 📁 Onde ficam os dados?

```
Dados do PostgreSQL:
/opt/lightrag/data/postgres/

Dados do Neo4j:
/opt/lightrag/data/neo4j/

Dados do LightRAG:
/opt/lightrag/data/rag_storage/

Documentos enviados:
/opt/lightrag/data/inputs/
```

**Importante:** Estas pastas NÃO desaparecem quando container reinicia!

---

## 🚀 Próximas ações

Depois que tiver tudo funcionando:

1. **Configure o GitHub para deploy automático**
   - Veja: `DEPLOYMENT_QUICK_START.md`

2. **Comece a usar o LightRAG**
   - Upload de documentos
   - Configure seu LLM provider
   - Faça buscas

3. **Faça backups regularmente**
   ```bash
   bash /opt/lightrag/backup.sh
   ```

---

## 📖 Documentação Completa

Para detalhes técnicos:
- **DATABASES.md** - Tudo sobre PostgreSQL e Neo4j
- **DEPLOYMENT.md** - Deploy automático
- **DEPLOYMENT_CHECKLIST.md** - Checklist de setup

---

**Pronto! Agora você tem um setup profissional com PostgreSQL + Neo4j!** 🎉

Alguma dúvida? Volte aos passos anteriores ou leia DATABASES.md para mais detalhes.
