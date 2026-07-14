# Segurança — Assistente de Caneta

Referência cruzada: LGPD art. 46 (medidas de segurança) e `juridico/POLITICA_PRIVACIDADE_LGPD.md` §5.

## Dados em repouso

- **AES-256-GCM campo a campo** (`src/utils/crypto.js`): peso, proteína, água, alimentos, efeitos, peso inicial e altura são cifrados **antes** de chegar ao banco. Formato `iv:authTag:ciphertext` (base64), IV aleatório de 12 bytes por valor.
- GCM fornece **autenticação**: valor adulterado no banco falha na decifração (testado em `tests/crypto.test.js`).
- A chave (`DATA_ENCRYPTION_KEY`, 32 bytes) vive **apenas** em variável de ambiente. Perda da chave = dados irrecuperáveis → manter cópia em cofre.
- Senhas: **bcrypt custo 12** (nunca armazenamos a senha).
- Refresh tokens: armazenados como **SHA-256** (vazamento do banco não vaza tokens).

## Dados em trânsito

- TLS terminado pelo Railway (HTTPS obrigatório em produção).
- `helmet` aplica HSTS, noSniff, frameguard etc.
- CORS restrito à origem do app (`CORS_ORIGIN`).

## Autenticação e autorização

- JWT de acesso curto (15 min) + refresh token de 30 dias revogável (logout/exclusão de conta revoga).
- RBAC: `paciente` / `profissional` / `admin` (middleware `requireRole`).
- Portal profissional: acesso **somente-leitura**, condicionado a (1) registro CRM/CRN verificado e (2) vínculo ativo criado pelo paciente.
- Rate limiting: 100 req/15min geral; 10 req/15min em auth (anti força bruta).

## LGPD por construção

- **HTTP 451** em qualquer rota de saúde sem consentimento `privacidade_saude` ativo.
- **Auditoria imutável**: middleware grava ator, ação, recurso e titular; trigger PostgreSQL impede UPDATE/DELETE em `audit_logs`.
- Exclusão: soft-delete + revogação de tokens imediatos; purga definitiva automática em 30 dias (job na API).
- Exportação completa em JSON num clique (portabilidade).

## Higiene de aplicação

- Validação de entrada com **Zod** em todos os endpoints (tipos, faixas, formatos).
- SQL 100% **parametrizado** (pg) — sem concatenação.
- Handler de erros central: stack e detalhes internos **nunca** vão ao cliente.
- Payload máximo 1 MB; usuário não-root no Docker.
- `.env` fora do git; `.env.example` sem segredos; chaves geradas por `npm run gen:keys`.

## Pendências de segurança (pré-launch — ver juridico/CHECKLIST_PRE_LAUNCH.md)

- [ ] Sentry com scrubbing de PII
- [ ] Scan OWASP ZAP no staging
- [ ] Teste de restauração de backup
- [ ] Rotação documentada de chaves (JWT pode rotacionar livre; DATA_ENCRYPTION_KEY exige re-cifragem — script a criar no Sprint 5)
- [ ] 2FA por e-mail para profissionais (Sprint 5)
