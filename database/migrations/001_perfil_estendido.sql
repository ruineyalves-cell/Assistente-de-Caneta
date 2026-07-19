-- ============================================================================
-- Migration 001 — Perfil estendido no backend (Lote 31)
--
-- Adiciona as colunas do perfil que antes ficavam só em SharedPreferences do
-- cliente. Assim, quando o usuário troca de aparelho ou reinstala o app, o
-- perfil (eixo farmacológico, identidade, sexo, última dose, meta de peso)
-- é restaurado do backend.
--
-- Idempotente: ADD COLUMN IF NOT EXISTS. Segura para rodar múltiplas vezes.
-- ============================================================================

ALTER TABLE patient_profiles
  ADD COLUMN IF NOT EXISTS eixo_farmacologico VARCHAR(40),
  ADD COLUMN IF NOT EXISTS identidade_genero  VARCHAR(30),
  ADD COLUMN IF NOT EXISTS sexo_biologico     VARCHAR(30),
  ADD COLUMN IF NOT EXISTS ultima_dose_iso    DATE,
  ADD COLUMN IF NOT EXISTS meta_peso_kg_enc   TEXT;
