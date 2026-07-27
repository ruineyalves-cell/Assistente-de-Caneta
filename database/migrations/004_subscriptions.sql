-- ============================================================================
-- Migration 004 — Play Billing subscriptions
--
-- Armazena estado de assinatura Premium por usuário, sincronizado com o
-- Google Play Android Publisher API. Uma linha por purchase_token (único
-- e imutável dentro de um ciclo de assinatura — Google emite novo token
-- em cada purchase, inclusive resubscribe após cancelamento).
--
-- Fonte de verdade continua sendo o Google Play. Esta tabela é um cache
-- local que evita chamar a Play API a cada request do app (rate limit
-- da API é 200k queries/dia — folgado, mas cachear é boa higiene).
--
-- Renovação: RTDN (Real-Time Developer Notifications) do Play → webhook
-- reconsulta a Play API e atualiza expiry_time / status. Como fallback
-- quando webhook falha, /api/assinaturas/status revalida se
-- `latest_check_at` está mais velho que 12h.
-- ============================================================================

CREATE TABLE IF NOT EXISTS subscriptions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purchase_token TEXT NOT NULL UNIQUE,
  product_id TEXT NOT NULL,
  order_id TEXT,
  status TEXT NOT NULL CHECK (status IN (
    'active',
    'canceled',
    'expired',
    'on_hold',
    'paused',
    'grace_period',
    'pending'
  )),
  expiry_time TIMESTAMPTZ,
  auto_renewing BOOLEAN NOT NULL DEFAULT false,
  acknowledged BOOLEAN NOT NULL DEFAULT false,
  start_time TIMESTAMPTZ,
  latest_check_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Consulta mais quente: "esse user ainda é premium?"
-- Filtra ativos com expiry no futuro; ordem DESC pra pegar mais recente.
CREATE INDEX IF NOT EXISTS ix_subscriptions_user_status
  ON subscriptions (user_id, status, expiry_time DESC);

-- RTDN webhook usa purchase_token pra reencontrar a assinatura.
-- Já tem UNIQUE index implícito, mas explicitamos por clareza.
-- (Postgres cria o índice automaticamente para colunas UNIQUE.)

-- Reconciliação periódica: quais assinaturas precisam de re-check?
CREATE INDEX IF NOT EXISTS ix_subscriptions_stale
  ON subscriptions (latest_check_at)
  WHERE status IN ('active', 'grace_period', 'on_hold');

COMMENT ON TABLE subscriptions IS 'Cache local de assinaturas Play. Fonte de verdade = Google Play API.';
COMMENT ON COLUMN subscriptions.purchase_token IS 'Token opaco do Play. Mudança de token = ciclo novo (novo purchase).';
COMMENT ON COLUMN subscriptions.status IS 'Deriva de expiryTimeMillis + paymentState + userCancellationTimeMillis.';
COMMENT ON COLUMN subscriptions.acknowledged IS 'Play EXIGE acknowledge em <=3d, senão faz refund automático.';
