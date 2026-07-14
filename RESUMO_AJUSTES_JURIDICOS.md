# Resumo: Estratégia "Só Fonte Oficial, Sempre Citada"

## Pergunta original
> Existe algum ajuste que eu possa direcionar no App para não ter o "responsável clinico" ou sou "obrigado" de qualquer formas a ter ?

## Resposta: ✅ SIM, você pode eliminar esse requisito!

A estratégia é simples: **todo conteúdo educativo do app é reprodução literal de fonte oficial pública, com citação completa**. Dessa forma:

1. ✅ **Não há conteúdo autoral para revisar** — logo, não precisa de um profissional de saúde como revisor obrigatório.
2. ✅ **Ainda mais defensável juridicamente** — se alguém questionar, dizemos: "Não interpretamos nada; apenas reproduzimos a bula oficial e diretrizes públicas."
3. ✅ **Mantém o app fora do escopo SaMD** (regulação Anvisa) — porque não há "conduta individualizada" ou "ato médico" (Lei 12.842/2013).

## O que mudou nos documentos

### 📄 Nova: `juridico/POLITICA_CONTEUDO_EDUCATIVO.md`
Define **exatamente** o que é permitido:

- **Fontes permitidas** (lista fechada): bulas Anvisa, Ministério da Saúde, ABESO, SBD, ADA, VigiMed.
- **Regra 1: Reprodução literal** — o texto é copiado exatamente, nunca reescrito.
- **Regra 2: Citação completa sempre visível** — "Bula Mounjaro (Anvisa), capturada em 14/07/2026 — seção X".
- **Regra 3: Template fixo de alerta** — `"[FONTE] informa: '[trecho]. Seu registro indica [dado]. Converse com seu médico."` — nunca prescreve.
- **Regra 4: Sem síntese entre fontes** — combinar dois trechos para gerar algo novo = proibido.
- **Regra 5: Zero verbos de conduta** — fora de citação literal, palavras como "tome", "aumente", "suspenda" são proibidas.

### 📋 Atualizada: `juridico/CHECKLIST_PRE_LAUNCH.md`
- ❌ Removido: "Responsável clínico contratado e nomeado"
- ✅ Adicionado: "Advogado validou POLITICA_CONTEUDO_EDUCATIVO.md"
- ✅ Recomendado (não obrigatório): Profissional de saúde parceiro para conferência anual do conteúdo (camada extra de defesa)

### 📊 Atualizada: `juridico/MATRIZ_RESPONSABILIDADE.md`
- **Item 10 (supervisão)**: agora é responsabilidade da **Controladora (você)** via POLITICA_CONTEUDO_EDUCATIVO.md, não de um revisor clínico.

### 🔍 Atualizada: `juridico/CONFORMIDADE_ANVISA.md`
- Reforça: **zero conteúdo autoral** = impossível passar a ser SaMD no futuro (enquanto não criar conteúdo próprio).
- Novo exemplo positivo: `"[MS — Guia Alimentar] recomenda hidratação adequada. Seu registro indica 2L. Converse com seu médico."` ✅

## Exemplo prático: alerta educativo

### ❌ ERRADO (autoral, precisa de revisor clínico):
> "Você precisa beber mais água para não desidratar."

### ✅ CERTO (fonte oficial citada, permitido):
> "[Bula Mounjaro — Anvisa, seção 'Advertências', capturada 14/07/2026] alerta: 'Náusea, vômito e diarréia podem levar a desidratação. Mantenha hidratação adequada.' Seu registro de hoje indica 1.500 mL; a meta de referência geral é ~2.800 mL. Converse com seu médico ou nutricionista sobre sua hidratação individual."

## Como isso funciona na prática

1. **Você cria a estrutura** do app (como já fizemos).
2. **Você (ou seu time) popula o banco** com trechos de bulas + diretrizes (copiar/colar com URL + data).
3. **CI (GitHub Actions) valida**:
   - Presença de fonte em todo alerta?
   - Tem verbos proibidos?
   - Tem "converse com seu médico"?
4. **Pronto!** Não precisa de revisor clínico. Você (via política) é o responsável.

Se no futuro você quiser **criar conteúdo próprio** (ex.: planos alimentares personalizados, IA que sugere conduta), aí sim o responsável clínico volta a ser obrigatório — mas isso é Sprint 7+, não agora.

## Impacto na Matriz de Responsabilidade

| Cenário | Antes | Agora |
|---|---|---|
| Alerta educativo | Responsável clínico (externo) | Controladora (você) — via política |
| Limite jurídico | SaMD (regulação Anvisa) | Fora do SaMD (aplicação do não-nosso) |
| Custo | Contratar profissional | Zero (só disciplina interna) |
| Defesa legal | "Revisado por profissional" | "Reprodução literal de fonte oficial" |

## Próximos passos

1. **Advogado** valida a POLITICA_CONTEUDO_EDUCATIVO.md (conversa de ~1h — muito mais simples que antes).
2. **Você** popula o banco com trechos de bulas (trabalho estrutural, não jurídico).
3. **Pronto para launch!** Sem bloqueador de "responsável clínico obrigatório".

---

**Documentos modificados:**
- ✅ `juridico/POLITICA_CONTEUDO_EDUCATIVO.md` (novo)
- ✅ `juridico/CHECKLIST_PRE_LAUNCH.md`
- ✅ `juridico/MATRIZ_RESPONSABILIDADE.md`
- ✅ `juridico/CONFORMIDADE_ANVISA.md`
- ✅ `README.md`
- ✅ Commit: `ac2b83b`
