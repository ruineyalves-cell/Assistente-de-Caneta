# Assistente de Caneta 💉📱

App de acompanhamento de conformidade para pacientes em tratamento com medicações GLP-1/GIP (Mounjaro, Ozempic, Wegovy, Saxenda, etc.) no Brasil.

> **O que este app É:** ferramenta de monitoramento e educação baseada em dados públicos (bulas Anvisa, ABESO, ADA).
> **O que este app NÃO É:** diagnóstico, prescrição ou substituto de acompanhamento médico.

## Estrutura do Projeto

```
Assistente-de-Caneta/
├── juridico/          # Documentos legais (LGPD, Termos, Disclaimers) — validar com advogado
├── backend/           # API Node.js 20 + Express (JWT, AES-256, LGPD compliance)
│   ├── src/
│   │   ├── config/        # Conexão PostgreSQL
│   │   ├── middleware/    # auth, lgpd, rateLimiter, errorHandler
│   │   ├── routes/        # Endpoints REST
│   │   ├── controllers/   # Lógica de negócio
│   │   ├── models/        # Queries SQL
│   │   └── utils/         # crypto (AES-256-GCM), metrics (motor de conformidade), pdf
│   └── tests/         # Jest
├── database/          # Schema PostgreSQL + migrations + seeds (7 medicações Brasil 2026)
└── docs/              # API.md, ARQUITETURA.md, SEGURANCA.md, DEPLOYMENT.md
```

## Rodar Localmente

Pré-requisitos: Node.js 20+, Docker Desktop.

```bash
# 1. Subir PostgreSQL local
docker compose up -d

# 2. Instalar dependências
cd backend
npm install

# 3. Configurar ambiente
cp .env.example .env
# edite .env (chaves geradas automaticamente com: npm run gen:keys)

# 4. Criar schema + dados iniciais
npm run db:migrate
npm run db:seed

# 5. Rodar
npm run dev          # http://localhost:3000
npm test             # testes unitários
```

## Stack (decidida — ver docs/ARQUITETURA.md)

| Camada | Ferramenta | Custo MVP |
|---|---|---|
| Backend | Node.js 20 + Express | R$ 0 |
| Banco | PostgreSQL 16 | R$ 0 (local) / incluído Railway |
| Auth | JWT próprio (bcrypt + refresh) — Firebase opcional depois | R$ 0 |
| Criptografia | AES-256-GCM (nativo `node:crypto`) | R$ 0 |
| PDF | pdfkit | R$ 0 |
| Deploy | Railway (região São Paulo) | R$ 10–30/mês |
| Erros | Sentry free tier | R$ 0 |
| Email | Resend free tier | R$ 0 |
| OCR (Tier 2) | Google Cloud Vision | R$ 0 (1k/mês) |

## Roadmap (Sprints)

- ✅ **Sprint 1** — Jurídico + Backend scaffolding + Schema + Motor de métricas *(este commit)*
- ⬜ **Sprint 2** — APIs completas de log diário + conformidade + testes de integração
- ⬜ **Sprint 3** — Flutter UI (seleção medicação, log diário, dashboard)
- ⬜ **Sprint 4** — Portal médico + PDF automático
- ⬜ **Sprint 5** — Segurança final + pacote para parecer jurídico
- ⬜ **Sprint 6** — Deploy Railway + beta

## ⚠️ Avisos

1. **Jurídico:** os documentos em `juridico/` são minutas técnicas — **exigem validação por advogado** antes do launch.
2. **Conteúdo educativo:** todo conteúdo é reprodução literal de fonte oficial pública (bulas Anvisa, ABESO, MS, etc.) com citação. Sem responsável clínico obrigatório. Ver `juridico/POLITICA_CONTEUDO_EDUCATIVO.md`.
3. **Dados sensíveis:** dados de saúde são criptografados em repouso (AES-256-GCM) e em trânsito (TLS).
