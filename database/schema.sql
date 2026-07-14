-- ============================================================
-- ASSISTENTE DE CANETA — Schema PostgreSQL 16
-- Convenção: campos com sufixo _enc são criptografados na
-- aplicação (AES-256-GCM, formato base64 "iv:tag:cipher")
-- e armazenados como TEXT. O banco nunca vê o valor em claro.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- gen_random_uuid()

-- ------------------------------------------------------------
-- USUÁRIOS E AUTENTICAÇÃO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           VARCHAR(255) NOT NULL UNIQUE,
  password_hash   VARCHAR(100) NOT NULL,           -- bcrypt
  role            VARCHAR(20)  NOT NULL CHECK (role IN ('paciente','profissional','admin')),
  nome            VARCHAR(160) NOT NULL,
  data_nascimento DATE         NOT NULL,           -- verificação 18+
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  -- LGPD: soft-delete imediato + purga definitiva pelo job em até 30 dias
  deleted_at      TIMESTAMPTZ,
  purge_after     TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  VARCHAR(128) NOT NULL,               -- sha256 do token
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens(user_id);

-- Registro de consentimento LGPD (art. 8º) — imutável
CREATE TABLE IF NOT EXISTS consents (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tipo          VARCHAR(40) NOT NULL,  -- 'termos_uso' | 'privacidade_saude' | 'disclaimer_medico'
  versao_doc    VARCHAR(20) NOT NULL,  -- ex.: '0.1'
  aceito        BOOLEAN NOT NULL,
  ip            VARCHAR(45),
  user_agent    VARCHAR(300),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_consents_user ON consents(user_id, tipo);

-- ------------------------------------------------------------
-- CATÁLOGO DE MEDICAÇÕES (dados públicos — bula Anvisa)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS medications (
  id                 SERIAL PRIMARY KEY,
  nome_comercial     VARCHAR(80)  NOT NULL,
  principio_ativo    VARCHAR(120) NOT NULL,
  fabricante         VARCHAR(120) NOT NULL,
  status_anvisa      VARCHAR(30)  NOT NULL CHECK (status_anvisa IN ('aprovado','nao_aprovado','em_analise')),
  categoria          VARCHAR(60)  NOT NULL,        -- ex.: 'GLP-1/GIP'
  indicacoes         TEXT         NOT NULL,
  frequencia_padrao  VARCHAR(40)  NOT NULL,        -- '1x/semana' | '1x/dia'
  via                VARCHAR(20)  NOT NULL DEFAULT 'subcutanea',
  doses_disponiveis  JSONB        NOT NULL DEFAULT '[]',
  preco_referencia   JSONB        NOT NULL DEFAULT '{}',
  receituario        VARCHAR(120) NOT NULL,        -- 'Receita retida (IN 360/2025)'
  bula_url           TEXT,
  fonte_capturada_em DATE,
  revisado_por       VARCHAR(160),                 -- responsável clínico
  observacoes        TEXT,
  ativo              BOOLEAN NOT NULL DEFAULT true,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- PERFIS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_profiles (
  user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  medication_id       INT REFERENCES medications(id),
  dose_atual          VARCHAR(30),                 -- informada pelo paciente (prescrição dele)
  frequencia          VARCHAR(40),
  peso_inicial_enc    TEXT,                        -- 🔒 sensível
  altura_cm_enc       TEXT,                        -- 🔒 sensível
  meta_proteina_gkg   NUMERIC(4,2) NOT NULL DEFAULT 1.20,  -- diretriz pública geral (ABESO): 1.2–1.6 g/kg
  meta_agua_ml_kg     NUMERIC(5,2) NOT NULL DEFAULT 35.00, -- diretriz pública geral: ~35 ml/kg
  declarou_prescricao BOOLEAN NOT NULL DEFAULT false,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS professional_profiles (
  user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  conselho       VARCHAR(10) NOT NULL CHECK (conselho IN ('CRM','CRN')),
  registro       VARCHAR(20) NOT NULL,
  uf             CHAR(2)     NOT NULL,
  verificado     BOOLEAN     NOT NULL DEFAULT false,  -- verificação manual/API conselho
  verificado_em  TIMESTAMPTZ,
  UNIQUE (conselho, registro, uf)
);

-- Vínculo paciente ↔ profissional (convite parte do PACIENTE)
CREATE TABLE IF NOT EXISTS patient_professional_links (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status          VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','ativo','revogado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  revogado_em     TIMESTAMPTZ,
  UNIQUE (patient_id, professional_id)
);

-- ------------------------------------------------------------
-- LOG DIÁRIO (dados de saúde — campos criptografados)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS daily_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  log_date       DATE NOT NULL,
  peso_kg_enc    TEXT,   -- 🔒
  proteina_g_enc TEXT,   -- 🔒
  agua_ml_enc    TEXT,   -- 🔒
  alimentos_enc  TEXT,   -- 🔒 texto livre
  dose_aplicada  BOOLEAN NOT NULL DEFAULT false,
  efeitos_enc    TEXT,   -- 🔒 efeitos percebidos (texto livre)
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (patient_id, log_date)
);
CREATE INDEX IF NOT EXISTS idx_logs_patient_date ON daily_logs(patient_id, log_date DESC);

-- Score de conformidade calculado (histórico — sem dados sensíveis em claro)
CREATE TABLE IF NOT EXISTS compliance_scores (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  log_date     DATE NOT NULL,
  score        SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 100),
  componentes  JSONB NOT NULL DEFAULT '{}',  -- {proteina: 80, hidratacao: 100, registro: 100}
  alertas      JSONB NOT NULL DEFAULT '[]',  -- alertas educativos gerados (código + fonte)
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (patient_id, log_date)
);

-- ------------------------------------------------------------
-- AUDITORIA LGPD (art. 37) — apenas INSERT, nunca UPDATE/DELETE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
  id            BIGSERIAL PRIMARY KEY,
  actor_user_id UUID,                       -- quem acessou (NULL = sistema)
  actor_role    VARCHAR(20),
  action        VARCHAR(40) NOT NULL,       -- 'read','create','update','delete','export','login'
  resource      VARCHAR(60) NOT NULL,       -- 'daily_logs','patient_profile',...
  resource_owner UUID,                      -- titular do dado acessado
  detalhe       JSONB,
  ip            VARCHAR(45),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_owner ON audit_logs(resource_owner, created_at DESC);

-- Impede alteração de trilha de auditoria
CREATE OR REPLACE FUNCTION deny_audit_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs é imutável (LGPD art. 37)';
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_immutable ON audit_logs;
CREATE TRIGGER trg_audit_immutable
  BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION deny_audit_mutation();
