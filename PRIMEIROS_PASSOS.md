# Primeiros Passos — Testar o App Localmente

## Pré-requisitos
- ✅ Docker Desktop instalado (via `INSTALAR_DOCKER.ps1`)
- ✅ Node.js 20+ (`node --version`)

## 1️⃣ Inicie o banco de dados

Na raiz do projeto (`Assistente-de-Caneta/`):

```bash
docker compose up -d
```

Aguarde ~5 segundos. Conferir se subiu:
```bash
docker ps
# deve listar um container "assistente-caneta-db" com status "Up"
```

## 2️⃣ Instale dependências e crie as chaves

Na pasta `backend/`:

```bash
cd backend
npm install
npm run gen:keys
```

Vai exibir algo como:
```
JWT_SECRET=abc...xyz
DATA_ENCRYPTION_KEY=def...uvw
```

Copie os dois valores. Agora:

```bash
cp .env.example .env
# Abra o arquivo .env e cole:
# JWT_SECRET=<cole aqui>
# DATA_ENCRYPTION_KEY=<cole aqui>
```

## 3️⃣ Configure o banco e popule com dados

```bash
npm run db:migrate    # cria schema
npm run db:seed       # insere 8 medicações
```

Se tudo funcionar, você vai ver:
```
✅ banco migrado com sucesso
ℹ️ medications já tem 8 registros — seed pulado
```

## 4️⃣ Rode a API

```bash
npm run dev
```

Você vai ver:
```
🚀 Assistente de Caneta API rodando em http://localhost:3000
   Health check: http://localhost:3000/health
```

## 5️⃣ Teste os endpoints (em outro terminal)

```bash
# Conferir que está rodando
curl http://localhost:3000/health

# Listar medicações (público — sem autenticação)
curl http://localhost:3000/api/medicacoes | jq

# Registrar paciente (POST)
curl -X POST http://localhost:3000/api/auth/registrar \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Maria Silva",
    "email": "maria@test.com",
    "senha": "Senha123!",
    "dataNascimento": "1990-05-10",
    "role": "paciente"
  }' | jq

# Resultado esperado:
# { "usuario": {...}, "accessToken": "jwt.token.here", "refreshToken": "..." }
```

## 6️⃣ Rode os testes

```bash
npm test

# Esperado: 15/15 testes passando ✅
```

## Troubleshooting

| Problema | Solução |
|---|---|
| `Error: connect ECONNREFUSED 127.0.0.1:5433` | Docker não está rodando. Execute `docker compose up -d` de novo. |
| `Error: password authentication failed` | Chave `DATA_ENCRYPTION_KEY` errada no `.env`. Rode `npm run gen:keys` e cole de novo. |
| `npm: command not found` | Node.js não está instalado. Baixe em https://nodejs.org (20 LTS). |
| `curl: command not found` | Abra um PowerShell e use `curl` (é um alias para `Invoke-WebRequest` — deve funcionar). |

## Próximo passo

Assim que conseguir rodar `npm run dev` e receber 200 em `/health`, avise! Passamos para o **Sprint 2** (testes de integração com o banco real).

---

**Tempo esperado:** 10–15 minutos (a primeira vez é mais lenta porque baixa imagens Docker).
