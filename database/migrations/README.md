# Migrations

- O schema base completo está em [`../schema.sql`](../schema.sql) — o comando `npm run db:migrate` (no `backend/`) aplica o schema base e depois **todas as migrations desta pasta em ordem alfabética**.
- Toda alteração de banco a partir do Sprint 2 entra aqui como novo arquivo: `NNN_descricao.sql` (ex.: `001_add_streaks.sql`).
- Migrations devem ser **idempotentes** (`IF NOT EXISTS` / `IF EXISTS`) — o runner é simples e reexecuta tudo.
- Nunca editar migration já aplicada em produção; criar uma nova.
