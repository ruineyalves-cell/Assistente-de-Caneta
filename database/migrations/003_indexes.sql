-- ============================================================================
-- Migration 003 — Índices críticos de performance (Lote G2)
--
-- Diagnóstico: sem esses índices, cada acesso ao dashboard faz sequential
-- scan em daily_logs (~N linhas × M usuários). Com poucos usuários beta
-- ninguém percebe, mas basta 500 DAU pra latência sair de 20 ms → 500 ms.
--
-- Cada CREATE INDEX é isolado + IF NOT EXISTS pra ser 100% idempotente.
-- Nomes de coluna verificados contra o dump real (agosto/2026).
-- ============================================================================

-- Query mais quente: GET /pacientes/logs?limit=N ordenado por data desc
-- Também usada por resumoDiario, preConsulta, alertas.
-- (Colunas reais: daily_logs.patient_id + daily_logs.log_date)
CREATE INDEX IF NOT EXISTS ix_daily_logs_patient_date
  ON daily_logs (patient_id, log_date DESC);

-- audit_logs(resource_owner, created_at DESC) — já existe como idx_audit_owner
-- criado pela seed schema. Pulamos aqui para não duplicar.

-- Refresh rotation (Lote S3): busca por refresh ativos de um usuário
-- (endpoint /auth/logout e reuse detection revogam família inteira).
-- Índice parcial: tokens revogados não interessam para nenhuma query quente.
CREATE INDEX IF NOT EXISTS ix_refresh_tokens_user_ativo
  ON refresh_tokens (user_id)
  WHERE revoked_at IS NULL;

-- Portal médico: listagem de pacientes vinculados ao profissional
-- (patient_professional_links.professional_id, created_at DESC).
CREATE INDEX IF NOT EXISTS ix_pp_links_prof_created
  ON patient_professional_links (professional_id, created_at DESC);

-- LGPD purge: SELECT users WHERE deleted_at IS NOT NULL AND purge_after < now()
-- roda a cada 12h em produção. Sem índice → seq scan em toda tabela users.
CREATE INDEX IF NOT EXISTS ix_users_purge_pendente
  ON users (purge_after)
  WHERE deleted_at IS NOT NULL;

-- consents: last-write-wins por (user_id, tipo) — sem índice a checagem
-- de consentimento no middleware requireConsent faz seq scan.
CREATE INDEX IF NOT EXISTS ix_consents_user_tipo
  ON consents (user_id, tipo, created_at DESC);
