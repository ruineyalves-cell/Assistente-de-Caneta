-- 002_refresh_rotation.sql
--
-- Rotação de refresh token com detecção de reuso (S3).
--
-- Adiciona `replaced_by_id` para encadear o token antigo ao novo
-- emitido no /auth/refresh. Se um refresh JÁ ROTACIONADO for reusado,
-- consideramos vazamento e revogamos toda a família do usuário.
--
-- Idempotente (IF NOT EXISTS) para rodar em auto-migrate do server.js.

ALTER TABLE refresh_tokens
  ADD COLUMN IF NOT EXISTS replaced_by_id UUID NULL
    REFERENCES refresh_tokens(id) ON DELETE SET NULL;

-- Índice para a query de reuso (procura por hash + revoked_at IS NULL).
-- Já existe UNIQUE em token_hash provavelmente; este é composto e cobre
-- o caminho quente do /refresh.
CREATE INDEX IF NOT EXISTS ix_refresh_tokens_hash_revoked
  ON refresh_tokens (token_hash, revoked_at);
