# Deploy — Assistente de Caneta

## Ambiente local (desenvolvimento)

```bash
# na raiz do projeto
docker compose up -d                 # PostgreSQL 16 na porta 5433

cd backend
npm install
cp .env.example .env
npm run gen:keys                     # cole JWT_SECRET e DATA_ENCRYPTION_KEY no .env
npm run db:migrate
npm run db:seed                      # catálogo de 8 medicações
npm run dev                          # http://localhost:3000/health
npm test                             # testes unitários
```

Smoke test rápido:
```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/medicacoes
```

## Produção — Railway (recomendado, R$ 10–30/mês)

1. Suba o repositório para o GitHub (repo privado).
2. Em [railway.app](https://railway.app): **New Project → Deploy from GitHub repo** → selecione a pasta `backend/` como root (Settings → Root Directory).
3. **Add PostgreSQL** no mesmo projeto (Railway injeta `DATABASE_URL`).
4. Variáveis (Settings → Variables):
   - `DATABASE_URL` → referência ao Postgres do projeto (`${{Postgres.DATABASE_URL}}`)
   - `PGSSL=true`
   - `JWT_SECRET`, `DATA_ENCRYPTION_KEY` → gere NOVAS com `npm run gen:keys` (⚠️ diferentes das locais; guarde a DATA_ENCRYPTION_KEY em cofre)
   - `CORS_ORIGIN` → origem do app em produção
   - `NODE_ENV=production`
5. Uma única vez, rode as migrations: Railway → serviço backend → **Run command**: `npm run db:migrate && npm run db:seed`.
6. Região: escolha **São Paulo** se disponível no seu plano (latência + argumento LGPD de dados no Brasil).
7. Domínio: Settings → Networking → Generate Domain (ou domínio próprio + HTTPS automático).

### Deploy contínuo
Todo push na branch `main` redeploya automaticamente. Use branch `dev` para trabalho e PR para `main`.

## Alternativa gratuita para o beta (custo R$ 0)

- **Render free tier** (o serviço dorme após inatividade — aceitável para beta fechado) + **Neon.tech** (PostgreSQL serverless free 0,5 GB).
- Mesmas variáveis de ambiente; `PGSSL=true`.

## Checklist de produção

- [ ] Chaves de produção distintas das de dev, guardadas em cofre
- [ ] `CORS_ORIGIN` sem `localhost`
- [ ] `npm run db:migrate` executado
- [ ] `/health` respondendo 200
- [ ] Backup automático do Postgres habilitado (Railway: incluído; confirmar retenção ≤35 dias p/ política LGPD)
- [ ] Sentry DSN configurado
- [ ] Ver `juridico/CHECKLIST_PRE_LAUNCH.md` antes do launch público
