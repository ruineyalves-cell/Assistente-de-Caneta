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

1. **Nenhuma saída do app pode orientar conduta clínica.** Alertas sempre no formato: *"[Fonte pública] recomenda X. Seu registro indica Y. Converse com seu médico."* — nunca *"faça X"* ou *"aumente/diminua Z"*.
2. **Score de conformidade** apresentado como "aderência ao seu plano de registro", não como indicador clínico; sem faixas de "risco".
3. **Sem interpretação individualizada**: as metas (proteína/kg, hidratação) vêm de diretriz pública geral, exibidas com fonte, ajustáveis apenas pelo profissional do paciente.
4. **Sem integração de decisão automática** com dispositivos (Health Connect apenas exibe, não atua).
5. Rotular o app nas lojas como **"Saúde e fitness / bem-estar"**, não "Médico".
6. Manter **dossiê técnico** (este documento + arquitetura + fontes) para eventual questionamento.

## 5. Conclusão preliminar

Com as mitigações do item 4, o app se enquadra como **software de bem-estar e gestão de dados autodeclarados**, fora do escopo de registro SaMD (RDC 657/2022, art. 1º, §2º). **Não requer registro Anvisa**, mas requer:

- ✅ Conformidade LGPD plena (dados sensíveis — art. 11);
- ✅ Responsável clínico revisor de conteúdo (boas práticas + defesa em eventual questionamento);
- ✅ Vigilância contínua: se qualquer feature futura passar a **interpretar dados para fins clínicos** (ex.: IA que sugere conduta), o enquadramento muda e o registro SaMD passa a ser exigido — reavaliar A CADA sprint.

## 6. Registro de decisões de produto com impacto regulatório

| Data | Decisão | Impacto |
|---|---|---|
| 2026-07 | Motor de métricas 100% determinístico, sem IA | Mantém fora do escopo SaMD |
| 2026-07 | Alertas sempre com fonte + "converse com seu médico" | Mantém fora do escopo SaMD |
| 2026-07 | OCR de receituário (fase 2) apenas preenche formulário, com confirmação manual | Baixo risco — sem decisão automática |

## 7. Checklist para o advogado regulatório

- [ ] Confirmar leitura do art. 1º, §2º, RDC 657/2022 aplicada a este produto
- [ ] Confirmar que "receita retida" (IN 360/2025) não impõe obrigações ao app (não vendemos medicamento)
- [ ] Confirmar não incidência da Res. CFM 2.314/2022 (telemedicina) no Portal Profissional somente-leitura
- [ ] Emitir parecer escrito para o dossiê
