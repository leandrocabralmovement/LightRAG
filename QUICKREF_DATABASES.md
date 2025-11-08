# 🚀 Quick Reference - PostgreSQL + Neo4j + LightRAG

Comandos e operações mais comuns. Salve em favoritos!

---

## ⚡ Iniciar / Parar

```bash
# Inicia tudo
docker-compose -f docker-compose.full.yml up -d --build

# Para tudo (dados continuam salvos)
docker-compose stop

# Inicia novamente
docker-compose start

# Para e remove containers (dados continuam salvos)
docker-compose down

# Para e remove TUDO incluindo dados (⚠️ cuidado!)
docker-compose down -v
```

---

## 📊 Verificar Status

```bash
# Containers rodando
docker ps

# Logs em tempo real
docker-compose logs -f lightrag

# Logs de um serviço
docker-compose logs postgres
docker-compose logs neo4j

# Tamanho dos dados
du -sh /opt/lightrag/data/

# Espaço em disco
df -h

# CPU/Memory
docker stats
```

---

## 🔄 Atualizar Código + Rebuild

```bash
# Pull código novo
git pull origin main

# Rebuild e restart
docker-compose -f docker-compose.full.yml up -d --build

# Ou passo a passo
docker-compose stop
docker-compose -f docker-compose.full.yml build
docker-compose start
```

---

## 💾 Backup & Restore

```bash
# Fazer backup NOW
bash backup.sh

# Backup vai para: ./backups/2024-01-15_10-30-45/

# Restaurar um backup
bash restore.sh ./backups/2024-01-15_10-30-45/

# Ver todos os backups
ls -la ./backups/

# Agendar backup diário (crontab)
crontab -e
# Adicionar: 0 2 * * * cd /opt/lightrag && bash backup.sh
```

---

## 🔑 Senhas & Configuração

```bash
# Editar .env
nano .env

# Ver uma variável específica
grep POSTGRES_PASSWORD .env

# Mudar senha (perigoso! melhor fazer backup primeiro)
nano .env
# Editar valores
docker-compose restart
```

---

## 🔍 Acessar Bancos de Dados

### PostgreSQL

```bash
# Via terminal
docker exec lightrag-postgres psql -U lightrag -d lightrag

# Queries úteis dentro do psql:
SELECT 1;                    # Teste simples
\dt                          # Listar tabelas
\d table_name                # Descrever tabela
SELECT COUNT(*) FROM ...;    # Contar registros
\q                           # Sair
```

### Neo4j

```bash
# Browser web: http://116.203.193.178:7474
# Login: neo4j / sua_senha

# Ou via terminal
docker exec lightrag-neo4j cypher-shell -u neo4j -p sua_senha

# Queries úteis:
RETURN 1;                    # Teste
MATCH (n) RETURN COUNT(n);   # Contar nodes
MATCH (n)-[r]-() RETURN COUNT(r);  # Contar relações
```

---

## 🧹 Limpeza

```bash
# Remover imagens Docker não usadas
docker image prune -a

# Remover containers parados
docker container prune

# Remover volumes não usados
docker volume prune

# Limpeza completa (⚠️ cuidado!)
docker system prune -a --volumes

# Limpar espaço de logs
docker exec lightrag truncate -s 0 /var/log/lightrag-deploy.log
```

---

## 📈 Performance

```bash
# Ver tamanho de cada banco
docker exec lightrag-postgres du -sh /var/lib/postgresql/data
du -sh /opt/lightrag/data/neo4j

# Ver queries lentas no PostgreSQL
docker exec lightrag-postgres psql -U lightrag -d lightrag \
  -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 5;"

# Ver heap usage Neo4j
docker logs lightrag-neo4j | grep "heap"
```

---

## 🔧 Troubleshooting Rápido

```bash
# Container não inicia?
docker-compose logs lightrag

# PostgreSQL conexão recusada?
sleep 60 && docker-compose up -d lightrag

# Neo4j lento?
docker-compose restart neo4j

# Sem espaço?
df -h
docker system prune -a

# Dados desapareceram?
bash restore.sh ./backups/data_mais_recente/

# Container travado?
docker-compose restart lightrag
```

---

## 🌐 Acessos

```
LightRAG Web UI:
  http://116.203.193.178:9621
  Usuario: admin
  Senha: (a que configurou)

Neo4j Browser:
  http://116.203.193.178:7474
  Usuario: neo4j
  Senha: (a que configurou em NEO4J_PASSWORD)

PostgreSQL:
  Host: localhost (ou 116.203.193.178)
  Port: 5432
  User: lightrag
  Password: (a que configurou em POSTGRES_PASSWORD)
```

---

## 📝 Monitorar Saúde

```bash
# Health check de cada serviço
docker inspect lightrag | grep -A 5 Health
docker inspect lightrag-postgres | grep -A 5 Health
docker inspect lightrag-neo4j | grep -A 5 Health

# Se algum mostrar "starting" ou "unhealthy", espere mais:
sleep 30
docker-compose ps
```

---

## 🚨 Emergências

```bash
# Container corrompido? Começar do zero (com dados salvos)
docker-compose down
rm -rf /opt/lightrag/data/*
docker-compose -f docker-compose.full.yml up -d --build

# Ou restaurar do backup
bash restore.sh ./backups/backup_mais_recente/

# Se banco de dados corrompeu totalmente
# (último recurso, vai perder dados desde último backup)
docker-compose down -v
docker-compose -f docker-compose.full.yml up -d
bash restore.sh ./backups/backup_mais_recente/
```

---

## 📚 Documentação Completa

```
Para detalhes completos:
  - Noob? Leia: SETUP_DATABASES_SIMPLES.md
  - Técnico? Leia: DATABASES.md
  - Deploy? Leia: DEPLOYMENT_QUICK_START.md
```

---

## 🔐 Reminders de Segurança

```bash
# NUNCA faça:
git add .env              # NÃO commitar .env
git commit .env           # NÃO commitar .env

# SEMPRE faça:
git add .env.production.example  # OK commitar exemplo
bash backup.sh                    # Backup regularmente
nano .env                        # Revisar senhas frequentemente
```

---

## 📊 Tamanhos Típicos

```
PostgreSQL database: 100MB - 2GB (depende do volume)
Neo4j database: 50MB - 500MB
LightRAG cache: 10MB - 100MB
Total inicial: ~200MB
```

Se ultrapassar 50GB, considere cleanup ou outra VPS.

---

**Última atualização:** 7 Nov 2025
**Use com:** `docker-compose -f docker-compose.full.yml`
