-- ============================================================================
-- Migration 006 — Novas canetas GLP-1 aprovadas no Brasil (até jul/2026)
--
-- Fonte: pesquisa do usuário (Anvisa / Diário Oficial da União, jul/2026).
-- Complementa o seed database/seeds/001_medications.sql com o que faltava.
--
-- IDEMPOTÊNCIA: INSERT ... SELECT ... WHERE NOT EXISTS por nome_comercial.
-- Sem DDL (nenhum ALTER/CREATE) → precisa só de INSERT, não de OWNER, então
-- NÃO dispara 42501 mesmo com role rotacionada. Seguro re-rodar.
--
-- ⚠️ Pré-launch: responsável clínico deve revisar cada linha, confirmar
-- doses/registro na Anvisa e preencher bula_url + revisado_por. Os
-- similares de 2026 entram com doses vazias de propósito (não inventadas).
-- ============================================================================

-- Trulicity — dulaglutida semanal (DM2; uso p/ peso é off-label).
INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Trulicity', 'Dulaglutida', 'Eli Lilly', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (uso para peso é off-label)', '1x/semana', 'subcutanea',
  '["0.75mg","1.5mg","3.0mg","4.5mg"]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-31',
  'Agonista GLP-1 semanal. Registro para DM2; prescrição para peso é off-label.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Trulicity');

-- Soliqua e Xultophy — combos GLP-1 + insulina, DM2 severo. Categoria
-- própria (NÃO mapeada a nenhum eixo de peso) pra não aparecerem como
-- opção de emagrecimento; ficam no catálogo por completude.
INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Soliqua', 'Insulina glargina + Lixisenatida', 'Sanofi', 'aprovado',
  'GLP-1 + insulina (combo)',
  'Diabetes tipo 2 (controle glicêmico severo — não é caneta de emagrecimento)',
  '1x/dia', 'subcutanea', '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-31',
  'Combinação GLP-1 + insulina, uso exclusivo p/ DM2 severo. Fora do escopo de peso.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Soliqua');

INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Xultophy', 'Insulina degludeca + Liraglutida', 'Novo Nordisk', 'aprovado',
  'GLP-1 + insulina (combo)',
  'Diabetes tipo 2 (controle glicêmico severo — não é caneta de emagrecimento)',
  '1x/dia', 'subcutanea', '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-31',
  'Combinação GLP-1 + insulina, uso exclusivo p/ DM2 severo. Fora do escopo de peso.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Xultophy');

-- ── Similares de semaglutida aprovados em 2026 (DM2) ──────────────────────
-- Registrados por comparação de eficácia com o Ozempic. Doses vazias de
-- propósito (confirmar na bula/Anvisa antes do launch). Categoria 'GLP-1'
-- → aparecem no eixo "GLP-1 simples".

-- EMS — aprovados em maio/2026.
INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Ozivy', 'Semaglutida', 'EMS', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-05-01',
  'Similar de semaglutida (EMS) aprovado pela Anvisa em maio/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Ozivy');

INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Semaclick', 'Semaglutida', 'EMS', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-05-01',
  'Similar de semaglutida (EMS) aprovado pela Anvisa em maio/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Semaclick');

-- Aprovados em 29/jul/2026 (publicados no DOU).
INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Owozy', 'Semaglutida', 'Ávita Care', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-29',
  'Similar de semaglutida (Ávita Care) aprovado no DOU em 29/jul/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Owozy');

INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Seemasun', 'Semaglutida', 'Sun Pharma', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-29',
  'Similar de semaglutida (Sun Pharma) aprovado no DOU em 29/jul/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Seemasun');

INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Zempneo', 'Semaglutida', 'Brainfarma', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-29',
  'Similar de semaglutida (Brainfarma) aprovado no DOU em 29/jul/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Zempneo');

INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Semavy', 'Semaglutida', 'Cosmed', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-29',
  'Similar de semaglutida (Cosmed) aprovado no DOU em 29/jul/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Semavy');

INSERT INTO medications
  (nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
   indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
   receituario, fonte_capturada_em, observacoes)
SELECT 'Orsema', 'Semaglutida', 'Ranbaxy', 'aprovado', 'GLP-1',
  'Diabetes tipo 2 (similar de semaglutida)', '1x/semana', 'subcutanea',
  '[]'::jsonb, '{}'::jsonb,
  'Receita de controle especial retida (IN Anvisa 360/2025)', '2026-07-29',
  'Similar de semaglutida (Ranbaxy) aprovado no DOU em 29/jul/2026. Confirmar doses/bula.'
WHERE NOT EXISTS (SELECT 1 FROM medications WHERE nome_comercial = 'Orsema');
