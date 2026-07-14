-- ============================================================
-- SEED: Medicações GLP-1/GIP — Brasil, julho/2026
-- Fonte: pesquisa Anvisa/CMED/bulas compilada em 2026-07.
-- ⚠️ Antes do launch: responsável clínico deve revisar cada
-- linha e preencher bula_url oficial + revisado_por.
-- ============================================================

INSERT INTO medications
(nome_comercial, principio_ativo, fabricante, status_anvisa, categoria, indicacoes,
 frequencia_padrao, via, doses_disponiveis, preco_referencia, receituario,
 bula_url, fonte_capturada_em, observacoes)
VALUES
('Mounjaro', 'Tirzepatida', 'Eli Lilly', 'aprovado', 'GLP-1/GIP (duplo agonista)',
 'Diabetes tipo 2; obesidade; sobrepeso com comorbidade (conforme bula)',
 '1x/semana', 'subcutanea',
 '["2.5mg","5mg","7.5mg","10mg","12.5mg","15mg"]',
 '{"caixa_2_canetas":"R$ 1.580–2.052","caixa_4_canetas":"R$ 3.160–4.104"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Único titular do registro de tirzepatida no Brasil. Versões manipuladas são proibidas.'),

('Ozempic', 'Semaglutida', 'Novo Nordisk', 'aprovado', 'GLP-1',
 'Diabetes tipo 2 (perda de peso é indicação do Wegovy)',
 '1x/semana', 'subcutanea',
 '["0.25mg","0.5mg","1mg","2mg"]',
 '{"dose_baixa_media":"R$ 1.077–1.399","dose_alta":"R$ 2.076–2.696"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Patente expirada (mar/2026) — genéricos de semaglutida em expansão. Semaglutida manipulada é proibida pela Anvisa.'),

('Wegovy', 'Semaglutida', 'Novo Nordisk', 'aprovado', 'GLP-1',
 'Obesidade e sobrepeso com comorbidade (indicação de peso, não diabetes)',
 '1x/semana', 'subcutanea',
 '["0.25mg","0.5mg","1mg","1.7mg","2.4mg"]',
 '{"mensal":"R$ 1.500–2.200"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Mesma molécula do Ozempic com indicação e escalonamento próprios para peso.'),

('Saxenda', 'Liraglutida', 'Novo Nordisk', 'aprovado', 'GLP-1',
 'Obesidade e sobrepeso com comorbidade',
 '1x/dia', 'subcutanea',
 '["0.6mg","1.2mg","1.8mg","2.4mg","3.0mg"]',
 '{"por_aplicador":"R$ 292–379","caixa_5":"~R$ 1.899"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Patente expirada — genéricos: Lirux, Olire (EMS). Aplicação DIÁRIA (não semanal).'),

('Poviztra', 'Semaglutida', 'Eurofarma', 'aprovado', 'GLP-1',
 'Diabetes tipo 2; obesidade (conforme registro Eurofarma)',
 '1x/semana', 'subcutanea',
 '["0.25mg","0.5mg","1mg"]',
 '{"referencia":"abaixo do preço Novo Nordisk"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Semaglutida nacional (Eurofarma) — alternativa de menor custo. Confirmar nome comercial/registro na Anvisa antes do launch.'),

('Victoza', 'Liraglutida', 'Novo Nordisk', 'aprovado', 'GLP-1',
 'Diabetes tipo 2 (não indicado para peso — para peso ver Saxenda)',
 '1x/dia', 'subcutanea',
 '["0.6mg","1.2mg","1.8mg"]',
 '{"caixa_2_aplicadores":"R$ 584–759"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Mesma molécula do Saxenda, indicação diabetes.'),

('Rybelsus', 'Semaglutida oral', 'Novo Nordisk', 'aprovado', 'GLP-1 oral',
 'Diabetes tipo 2',
 '1x/dia', 'oral',
 '["3mg","7mg","14mg"]',
 '{"combo_2_caixas":"R$ 565–615"}',
 'Receita de controle especial retida (IN Anvisa 360/2025)',
 NULL, '2026-07-14',
 'Única opção GLP-1 ORAL no Brasil. Tomar em jejum com pouca água (bula).'),

('Retatrutida', 'Retatrutida', 'Eli Lilly', 'nao_aprovado', 'GLP-1/GIP/GCG (triplo agonista)',
 'Em estudos fase 3 (obesidade severa, diabetes) — SEM registro Anvisa',
 '1x/semana', 'subcutanea',
 '[]',
 '{"estimativa_pos_aprovacao":"R$ 2.000–3.000/mês"}',
 'NÃO COMERCIALIZADO LEGALMENTE NO BRASIL',
 NULL, '2026-07-14',
 'NÃO selecionável pelo paciente (ativo=true apenas para fins informativos/alerta). Qualquer versão "manipulada" é ilegal e perigosa.');

-- Retatrutida não pode ser selecionada como medicação em uso:
UPDATE medications SET ativo = false WHERE status_anvisa <> 'aprovado';
