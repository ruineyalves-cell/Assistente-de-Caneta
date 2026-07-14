# Arquitetura — Assistente de Caneta

## Visão geral

```
┌──────────────────────┐        HTTPS/TLS         ┌─────────────────────────────┐
│  App Flutter          │ ───────────────────────▶ │  API Node.js 20 + Express    │
│  (iOS/Android/Web)    │   JWT Bearer             │  Railway (São Paulo)         │
│  Sprint 3             │                          │                             │
└──────────────────────┘                          │  helmet + cors + rate limit │
                                                  │  auth (JWT) → consent (LGPD)│
┌──────────────────────┐                          │  → audit → controller       │
│  Portal Profissional  │ ───────────────────────▶ │                             │
│  (mesma API, role     │   read-only              └──────────┬──────────────────┘
│   profissional)       │                                     │ pg (pool)
└──────────────────────┘                          ┌──────────▼──────────────────┐
                                                  │  PostgreSQL 16               │
                                                  │  dados de saúde: AES-256-GCM │
                                                  │  audit_logs imutável         │
                                                  └─────────────────────────────┘
```

## Decisões e justificativas

| Decisão | Justificativa |
|---|---|
| **Node.js + Express (não NestJS)** | Time de 1 pessoa; menos abstração = mais fácil de manter; migração p/ Nest é trivial se crescer |
| **PostgreSQL (não MongoDB)** | ACID para dados sensíveis; JSONB dá flexibilidade onde precisa (doses, alertas) |
| **Criptografia na aplicação (campo a campo), não no banco** | O banco (e backups, e o provedor) nunca vê dado de saúde em claro; chave fica só no ambiente da API |
| **Motor de métricas determinístico, sem IA** | Mantém o app fora do escopo SaMD/Anvisa (ver juridico/CONFORMIDADE_ANVISA.md); auditável linha a linha |
| **JWT próprio (não Firebase) no MVP** | Zero dependência externa p/ rodar local; refresh token revogável no banco; Firebase pode ser plugado depois |
| **Consentimento como middleware (HTTP 451)** | Impossível esquecer: nenhuma rota de saúde executa sem consentimento ativo |
| **Auditoria como middleware + trigger de imutabilidade** | LGPD art. 37; trilha à prova de UPDATE/DELETE no próprio banco |
| **Soft-delete + purga em 30 dias** | LGPD art. 18, VI com janela para arrependimento e purga automática |
| **Railway como infra** | PostgreSQL incluído, deploy via Git, região São Paulo, R$ 10–30/mês, escala sem re-arquitetura |

## Camadas do backend

```
routes/index.js      → mapeamento URL → middlewares → controller
middleware/          → auth (JWT), lgpd (consent + audit), rateLimiter, errorHandler
controllers/         → validação (zod) + orquestração + regras de negócio
models/              → SQL parametrizado + criptografia/descriptografia de campos
utils/               → crypto (AES-256-GCM), metrics (motor puro, testável), pdf
```

O motor de métricas (`utils/metrics.js`) é **função pura** — sem banco, sem rede — o que permite testá-lo exaustivamente e auditá-lo juridicamente.

## Modelo de dados (resumo)

- `users` — pacientes, profissionais, admin (bcrypt, soft-delete LGPD)
- `consents` — trilha imutável de aceites/revogações por versão de documento
- `medications` — catálogo público versionado (bula, preço CMED, receituário)
- `patient_profiles` — medicação em uso + metas (campos sensíveis `_enc`)
- `professional_profiles` — CRM/CRN + flag `verificado`
- `patient_professional_links` — vínculo criado pelo paciente, revogável
- `daily_logs` — 1 registro/dia (peso, proteína, água, alimentos, efeitos — todos `_enc`)
- `compliance_scores` — score diário + componentes + alertas gerados
- `audit_logs` — quem acessou o quê de quem (INSERT-only, trigger bloqueia mutação)

## Escalabilidade

- Pool de conexões pg (10) — Railway escala vertical sem mudança de código
- Score é pré-calculado no write (`compliance_scores`) — dashboards leem sem recomputar
- Próximos passos quando necessário: réplica de leitura, Redis para rate-limit distribuído, fila (BullMQ) para PDF/e-mail

## Sprint 3 (Flutter) — contrato

O app consome exclusivamente a API acima. Estado local mínimo (tokens em `flutter_secure_storage`), offline-first opcional na v1.1 (fila de logs pendentes).
