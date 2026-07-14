# POLÍTICA DE CONTEÚDO EDUCATIVO — "SÓ FONTE OFICIAL, SEMPRE CITADA"

> Decisão de produto (2026-07): o app **não produz conteúdo clínico autoral**. Todo conteúdo educativo é **reprodução literal de fonte oficial pública já validada**, com citação completa. Isso elimina a necessidade jurídica de um responsável clínico revisor (não há conteúdo nosso a validar) e reforça o enquadramento fora do escopo SaMD.
> **Validar esta política com o advogado** — ela é a peça central da defesa de conteúdo.

## 1. Fontes permitidas (lista fechada)

| Fonte | O que usamos | Autoridade validadora |
|---|---|---|
| **Bulário Eletrônico Anvisa** (bulas de paciente) | Advertências, precauções, reações adversas, modo de uso | Anvisa |
| **Anvisa — comunicados e alertas** | Ex.: proibição de semaglutida/tirzepatida manipuladas | Anvisa |
| **Ministério da Saúde** (guias alimentares, materiais públicos) | Guia Alimentar para a População Brasileira; hidratação | MS |
| **ABESO** — Diretrizes Brasileiras de Obesidade | Metas de proteína, preservação de massa magra | ABESO |
| **SBD** — Diretrizes da Sociedade Brasileira de Diabetes | Automonitoramento, hipoglicemia | SBD |
| **ADA** — Standards of Care | Automonitoramento (uso secundário, sempre com tradução marcada) | ADA |
| **VigiMed/Anvisa** | Instruções de notificação de evento adverso | Anvisa |

Nenhuma outra fonte é permitida (nada de portais de notícia, blogs, influenciadores, fabricantes fora da bula aprovada, IA generativa).

## 2. Regras de reprodução (invioláveis)

1. **Literal ou nada**: o trecho é reproduzido textualmente. Se precisar encurtar, corta-se com reticências — nunca se reescreve com outras palavras.
2. **Citação completa sempre visível**: fonte + documento + data de captura + link. Ex.: *"Bula Mounjaro (paciente), Anvisa — Bulário Eletrônico, capturada em 14/07/2026 — seção 'Advertências'."*
3. **Template fixo de alerta** (o app nunca formula recomendação):
   > "[FONTE] informa: '[trecho literal]'. Seu registro de hoje indica [dado do usuário]. Converse com seu médico ou nutricionista."
4. **Verbos proibidos** em qualquer texto do app dirigido ao usuário: tome, aplique, aumente, reduza, suspenda, substitua, faça jejum, evite (fora de citação literal). O app **relata e cita**; nunca **manda**.
5. **Zero síntese entre fontes**: combinar duas fontes para gerar uma orientação nova = conteúdo autoral = proibido.
6. **Traduções** (ADA): marcadas como "tradução livre" com link para o original em inglês.

## 3. Processo de manutenção (sem revisor clínico)

- Cada trecho educativo vive na base de dados com: `texto`, `fonte`, `documento`, `url`, `data_captura`, `hash_do_original`.
- **Reverificação trimestral**: conferir se a bula/diretriz mudou (bulas Anvisa têm versão datada). Trecho desatualizado é substituído, nunca editado — o histórico fica no banco (dossiê de defesa).
- Toda alteração de conteúdo passa por checklist automatizado (CI): verbos proibidos, presença de fonte, presença de "converse com seu médico".

## 4. O que ainda recomendamos (não obrigatório)

- Um profissional de saúde parceiro para **conferência anual** do conjunto (custo baixo, ex.: parecer avulso) — vale como camada extra de defesa e argumento de marketing ("conteúdo conferido por profissional"), mas **não é condição de launch**.
- Se um dia o app gerar recomendações individualizadas (IA, planos alimentares), esta política cai e o responsável clínico + reavaliação SaMD tornam-se **obrigatórios**.

## 5. Fundamento jurídico do modelo

- Reproduzir informação pública oficial com citação não constitui exercício da medicina (Lei 12.842/2013) nem da nutrição — não há ato privativo, não há paciente atendido, não há conduta individualizada.
- Não constitui propaganda de medicamento (RDC 96/2008) — o conteúdo aparece apenas dentro do contexto do tratamento **já prescrito e declarado** pelo usuário, sem estímulo de consumo.
- Direito autoral: bulas e normas são atos oficiais (art. 8º, IV, Lei 9.610/98 — sem proteção autoral); diretrizes ABESO/SBD/ADA são citadas em trechos curtos com atribuição (art. 46, III).
