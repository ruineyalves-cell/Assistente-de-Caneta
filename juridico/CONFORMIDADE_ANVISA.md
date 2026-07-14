# ANÁLISE DE CONFORMIDADE ANVISA — ENQUADRAMENTO REGULATÓRIO

> Documento técnico-jurídico interno. **Conclusões preliminares — validar com advogado especializado em regulatório de saúde.**

## 1. Pergunta central

O Assistente de Caneta é um **SaMD** (Software as a Medical Device) sujeito a registro na Anvisa (RDC 657/2022 e RDC 751/2022), ou um **software de bem-estar/registro** fora do escopo regulatório?

## 2. Norma aplicável

- **RDC 657/2022** — regulariza software como dispositivo médico (SaMD).
- Art. 1º, §2º da RDC 657/2022 **exclui** do escopo, entre outros:
  - software destinado a **bem-estar** (wellness);
  - software que faz **gestão administrativa** de dados de saúde;
  - software que apenas **armazena, comunica ou exibe** dados sem interpretá-los para fins de diagnóstico/tratamento.

## 3. Análise funcional do app (versão MVP)

| Funcionalidade | Interpreta dados p/ diagnóstico ou tratamento? | Enquadramento |
|---|---|---|
| Registro de peso/proteína/água/refeições | Não — armazenamento e exibição | Fora do escopo SaMD |
| Registro de aplicações da medicação prescrita | Não — diário do próprio paciente | Fora do escopo SaMD |
| Exibição de trechos de bula com fonte | Não — reprodução de informação pública | Fora do escopo SaMD |
| Score de conformidade (% de aderência a metas gerais públicas) | **Zona cinzenta** — é cálculo determinístico educativo, não clínico | Mitigar (ver 4) |
| Alertas educativos ("a bula recomenda X, você registrou Y") | **Zona cinzenta** — comparação informativa | Mitigar (ver 4) |
| Portal do profissional (leitura + PDF) | Não — comunicação de dados autodeclarados | Fora do escopo SaMD |

## 4. Estratégia de mitigação (para permanecer fora do escopo SaMD)

A estratégia é tripla, reforçada pela **POLITICA_CONTEUDO_EDUCATIVO.md**:

1. **Zero conteúdo autoral**: todo alerta é reprodução LITERAL de fonte oficial pública (Anvisa, ABESO, MS, etc.) com citação completa. Exemplos:
   - ❌ "Você deveria beber mais água" ← nosso; proibido.
   - ✅ "[MS — Guia Alimentar para a População Brasileira] recomenda hidratação adequada. Seu registro indica 2L. Converse com seu médico." ← fonte citada; permitido.

2. **Nenhuma orientação clínica original**: verbos de conduta proibidos fora de citação literal ("tome", "aumente", "suspenda", "evite"). Alertas sempre seguem template fixo: "[FONTE] informa: [trecho]. Seu registro indica [dado]. Converse com seu médico."

3. **Score de conformidade** apresentado como "aderência ao seu plano de registro", não como indicador clínico; sem faixas de "risco".

4. **Sem interpretação individualizada**: as metas (proteína/kg, hidratação) vêm de diretriz pública geral (ABESO, MS), exibidas com fonte, ajustáveis apenas pelo profissional do paciente.

5. **Sem integração de decisão automática** com dispositivos (Health Connect apenas exibe, não atua).

6. Rotular o app nas lojas como **"Saúde e fitness / bem-estar"**, não "Médico".

7. Manter **dossiê técnico** (este documento + POLITICA_CONTEUDO_EDUCATIVO.md + arquitetura + hash dos originais) para eventual questionamento.

## 5. Conclusão preliminar

Com as mitigações do item 4 (especialmente zero conteúdo autoral), o app se enquadra como **software de bem-estar e gestão de dados autodeclarados**, fora do escopo de registro SaMD (RDC 657/2022, art. 1º, §2º). **Não requer registro Anvisa**, mas requer:

- ✅ Conformidade LGPD plena (dados sensíveis — art. 11);
- ✅ Política de Conteúdo Educativo rigorosa e auditável (POLITICA_CONTEUDO_EDUCATIVO.md);
- ✅ Checklist CI no pipeline (verificar verbos proibidos, presença de fonte, presença de "converse com seu médico");
- ✅ Professional de saúde parceiro para conferência anual (recomendado, não obrigatório — camada de defesa);
- ✅ Vigilância contínua: se qualquer feature futura passar a **criar conteúdo autoral ou interpretar dados para fins clínicos** (ex.: IA que sugere conduta, planos alimentares personalizados), o enquadramento muda e o registro SaMD passa a ser exigido — reavaliar A CADA sprint.

## 6. Registro de decisões de produto com impacto regulatório

| Data | Decisão | Impacto |
|---|---|---|
| 2026-07-14 | Motor de métricas 100% determinístico, sem IA | Mantém fora do escopo SaMD |
| 2026-07-14 | POLITICA_CONTEUDO_EDUCATIVO.md: conteúdo SEMPRE é reprodução literal de fonte oficial (Anvisa, ABESO, MS, ADA) com citação completa | Elimina necessidade de responsável clínico revisor; mantém fora do escopo SaMD; robusto juridicamente (não é conteúdo nosso, é citado) |
| 2026-07-14 | Alertas seguem template fixo + sempre terminam com "converse com seu médico" | Reforça que não é orientação clínica |
| 2026-07-14 | OCR de receituário (fase 2) apenas preenche formulário, com confirmação manual | Baixo risco — sem decisão automática |

## 7. Checklist para o advogado regulatório

- [ ] Confirmar leitura do art. 1º, §2º, RDC 657/2022 aplicada a este produto
- [ ] Confirmar que "receita retida" (IN 360/2025) não impõe obrigações ao app (não vendemos medicamento)
- [ ] Confirmar não incidência da Res. CFM 2.314/2022 (telemedicina) no Portal Profissional somente-leitura
- [ ] Emitir parecer escrito para o dossiê
