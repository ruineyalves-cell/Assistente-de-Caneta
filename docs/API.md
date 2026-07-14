# API — Assistente de Caneta (v0.1)

Base URL local: `http://localhost:3000`
Autenticação: `Authorization: Bearer <accessToken>` (JWT, expira em 15 min; renove com refresh token).
Todas as respostas são JSON, exceto o relatório PDF.

## Fluxo típico do paciente

1. `POST /api/auth/registrar` → recebe tokens
2. `POST /api/lgpd/consentimento` ×3 (termos_uso, privacidade_saude, disclaimer_medico) — **sem o consentimento `privacidade_saude` aceito, todo endpoint de saúde responde `451`**
3. `GET /api/medicacoes` → paciente escolhe a medicação prescrita
4. `PUT /api/pacientes/perfil` com `declarouPrescricao: true`
5. `POST /api/logs` diariamente → recebe score + alertas educativos
6. `GET /api/logs/dashboard` → cards, streak, histórico

---

## Auth

### POST /api/auth/registrar
```json
{ "nome": "Maria Silva", "email": "maria@ex.com", "senha": "minimo8chars",
  "dataNascimento": "1990-05-10", "role": "paciente" }
```
Profissional: acrescente `"role": "profissional", "conselho": "CRM", "registro": "123456", "uf": "SP"`.
`201` → `{ usuario, accessToken, refreshToken }`. Menores de 18: `403`.

### POST /api/auth/login
`{ "email", "senha" }` → `200 { usuario, accessToken, refreshToken }`

### POST /api/auth/refresh
`{ "refreshToken" }` → `200 { accessToken }`

### POST /api/auth/logout 🔒
`{ "refreshToken" }` → revoga o refresh token.

## Medicações (público — dados de bula)

### GET /api/medicacoes
Lista as medicações **aprovadas pela Anvisa** (7 em jul/2026). Retatrutida não aparece (sem registro).

### GET /api/medicacoes/:id
Detalhe com doses, preço de referência, receituário e observações.

## LGPD 🔒

| Endpoint | Direito | Retorno |
|---|---|---|
| `POST /api/lgpd/consentimento` `{tipo, versaoDoc, aceito}` | Consentimento (art. 8º/11) | `201` |
| `GET /api/lgpd/consentimentos` | Histórico de aceites | lista |
| `GET /api/lgpd/exportar` | Portabilidade (art. 18, V) | JSON completo p/ download |
| `GET /api/lgpd/acessos` | Quem acessou meus dados (art. 18, VII) | trilha de auditoria |
| `DELETE /api/lgpd/conta` `{confirmo: true}` | Eliminação (art. 18, VI) | desativa já, purga ≤30d |

## Paciente 🔒 (role `paciente` + consentimento ativo)

### PUT /api/pacientes/perfil
```json
{ "medicationId": 1, "doseAtual": "5mg", "frequencia": "1x/semana",
  "pesoInicialKg": 98.5, "alturaCm": 172, "declarouPrescricao": true,
  "metaProteinaGkg": 1.2, "metaAguaMlKg": 35 }
```
`declarouPrescricao: false` → `403` (Termos §3.1). Medicação não aprovada → `400`.

### GET /api/pacientes/perfil
### POST /api/pacientes/profissionais — `{ "email": "dr@ex.com" }` convida profissional (vínculo parte do paciente)
### DELETE /api/pacientes/profissionais/:id — revoga acesso
### GET /api/pacientes/profissionais

## Log diário 🔒

### POST /api/logs
```json
{ "data": "2026-07-14", "pesoKg": 97.8, "proteinaG": 110, "aguaMl": 2800,
  "alimentos": "frango, arroz, salada", "doseAplicada": true, "efeitos": "leve náusea" }
```
`201` →
```json
{ "data": "2026-07-14", "score": 93,
  "componentes": { "proteina": 94, "hidratacao": 82, "registro": 100 },
  "alertas": [ { "codigo": "HIDRATACAO_BAIXA", "mensagem": "...", "fonte": "Bula (Anvisa)...",
                 "rodape": "Alerta educativo. Não é recomendação médica..." } ] }
```
Upsert por dia: repetir a chamada atualiza o log do dia.

### GET /api/logs?desde=2026-06-01&ate=2026-07-14
### GET /api/logs/dashboard
`{ hoje, pesoAtualKg, streak, scores28dias, metas, rodape }`

## Portal do profissional 🔒 (role `profissional`, registro verificado)

| Endpoint | Descrição |
|---|---|
| `GET /api/portal/pacientes` | Pacientes com vínculo ativo |
| `GET /api/portal/pacientes/:id` | Dashboard read-only (auditado) |
| `GET /api/portal/pacientes/:id/relatorio.pdf` | PDF com disclaimer + hash |

Profissional não verificado → `403`. Sem vínculo ativo → `403`. Todo acesso é gravado em `audit_logs` com o paciente como titular.

## Códigos de erro

| Código | Significado |
|---|---|
| 400 | Payload inválido (detalhes por campo — Zod) |
| 401 | Token ausente/inválido |
| 403 | Papel errado, sem vínculo, menor de idade, sem prescrição declarada |
| 404 | Recurso inexistente |
| 409 | Duplicado (ex.: e-mail já cadastrado) |
| 429 | Rate limit |
| 451 | Consentimento LGPD pendente |
| 500 | Erro interno (sem vazamento de detalhes) |
