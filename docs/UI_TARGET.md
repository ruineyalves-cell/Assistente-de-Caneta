# UI Target — Especificação viva

Os SVGs em [`play-store/assets/`](./play-store/assets/) foram
desenhados como **screenshots aspiracionais** para a Play Store, mas
acabaram servindo também como **norte de UX do app**. Este documento
formaliza esse duplo papel.

## Regras

1. Quando o app **divergir** dos screenshots num ponto que degrade UX,
   este documento é o norte — o app se ajusta.
2. Quando o **screenshot** parecer irrealista ou poético demais para a
   realidade Flutter, **os screenshots é que são atualizados** — não
   forçamos o app a copiar pixel a pixel.
3. Screenshots são spec **macro** (fluxo, hierarquia, tokens), não
   micro (radius exato, sombra exata).

## Mapa card → ação esperada no dashboard

| Card       | Ação esperada                            | Estado atual              | Screenshot |
| ---------- | ---------------------------------------- | ------------------------- | ---------- |
| Refeição   | Abre câmera → resultado → sintomas       | ✅ implementado           | 1, 2       |
| Água       | `WaterQuickSheet` (+250/+500/+750/+1L)   | ✅ **Lote 32**            | 2          |
| Peso       | `WeightQuickSheet` (input + local)       | ✅ **Lote 32**            | 2          |
| Sintomas   | `SymptomsSheet` (chips + intensidade)    | ✅ implementado           | 4          |

## Princípios de UX que os screenshots consagram

### 1. Cada eixo, uma ação

Card do dashboard = **uma coisa só**. Não abrir formulário genérico
com múltiplos campos. O usuário toca em "Água" porque quer registrar
água — não peso, proteína, alimentos e dose de uma vez.

O botão **"Registrar de hoje"** (form completo) segue existindo como
caminho avançado para quem quer preencher tudo numa tela.

### 2. Feedback tátil visível

Sheets de água somam **na hora** (não navegam pra tela nova). Sheet de
peso mostra **delta em relação ao último** enquanto digita — o usuário
vê a evolução antes mesmo de salvar.

### 3. Local do peso importa

A escolha entre **casa · academia · farmácia · clínica** é armazenada
como observação no log (campo `alimentos`), aparece no PDF médico e o
último local escolhido é lembrado no próximo uso.

### 4. Cor por eixo, não por status

Refeição = laranja. Água = ciano. Peso = verde-menta. Sintomas = coral.

**Nunca** usar vermelho ou verde para "bom/ruim" fora dos alertas
clínicos. A cor do eixo é identidade — o valor semântico (progresso,
regressão) vem da posição na tela, do delta e do texto.

### 5. Farmacovigilância seria

Chips de sintomas em bloco 3×N, seleção múltipla. Intensidade em 3
níveis com emojis (🙂 leve · 😐 moderada · 😖 intensa). Sempre com
referência à bula Anvisa quando o sintoma é marcado como intenso.

## Referência dos SVGs

- [screenshot-1-boas-vindas.svg](./play-store/assets/screenshot-1-boas-vindas.svg) — onboarding target
- [screenshot-2-dashboard.svg](./play-store/assets/screenshot-2-dashboard.svg) — dashboard target
- [screenshot-3-lembrete-dose.svg](./play-store/assets/screenshot-3-lembrete-dose.svg) — dose reminder target
- [screenshot-4-sintomas.svg](./play-store/assets/screenshot-4-sintomas.svg) — sintomas target
- [screenshot-5-pdf-medico.svg](./play-store/assets/screenshot-5-pdf-medico.svg) — PDF médico target

## Histórico de alinhamentos

- **Lote 32 (2026-07-19)** — Água e Peso ganharam sheets focados
  alinhados aos screenshots. Antes ambos abriam `LogDailyPage`.
