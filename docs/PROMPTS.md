# Prompts prontos para o Claude Code — Projeto MyoSync

Use cada bloco na ordem. Copie o conteúdo dentro das cercas ``` e cole no Claude Code.

---

## PROMPT 0 — Verificar o ambiente (rode primeiro de tudo)

Use depois de instalar Flutter + Android Studio e conectar o S25 Ultra via USB.

```
Estou no Windows com um Samsung S25 Ultra conectado via USB e depuração USB
ativada. Rode `flutter doctor -v` e depois `flutter devices`. Me mostre os
dois resultados e diga se meu celular já aparece como dispositivo disponível.
Se algo estiver com [x] ou faltando, me diga exatamente o que fazer para
resolver, um item de cada vez.
```

---

## PROMPT 1 — Adicionar as dependências novas

```
Adicione as dependências do arquivo docs/DEPENDENCIAS_NOVAS.md ao meu
pubspec.yaml SEM remover nenhuma das que já existem. Depois rode
`flutter pub get`. Se alguma já estiver presente, apenas ajuste a versão se
a minha for mais antiga; não duplique.
```

---

## PROMPT 2 — Auditoria contra o PRD (NÃO altera código)

```
MODO AUDITORIA — NÃO altere nenhum arquivo de código nesta etapa. Apenas
leia e reporte.

A fonte de verdade do produto está em docs/PRD.md.

TAREFA: audite o código atual do projeto contra o PRD e salve um relatório
como docs/AUDITORIA.md, com estas seções:

1. INVENTÁRIO: liste as telas/arquivos que já existem e o que cada um faz hoje.
2. CONFORMIDADE COM O PRD: para cada funcionalidade core, marque [OK] /
   [PARCIAL] / [FALTANDO]. Cubra: Disclaimer (LGPD/HIPAA), Perfil (gênero +
   sexo biológico + eixo farmacológico), Dashboard de recomposição, Macros
   de blindagem (proteína), Scanner de refeição (IA de visão), OCR de
   prescrição, Hub de smartwatch (FC + gasto ativo + hidratação), Ajuste de
   esforço (corrida/ciclismo), Relatório PDF para médico.
3. IDENTIDADE VISUAL: confirme Azul Clínico #2B6CB0 e fundo #F4F7FA. Aponte
   cores fora do padrão.
4. DÉBITOS TÉCNICOS: aponte usos de .withOpacity (deprecado), gráficos
   desenhados à mão em vez de fl_chart, estado só em setState sem
   persistência, dependências faltando.
5. RECOMENDAÇÃO: para cada item PARCIAL ou FALTANDO, diga APROVEITAR ou
   REFAZER, com uma linha de justificativa.

Não escreva código de correção agora. Só o relatório. Ao terminar, me avise.
```

---

## PROMPT 3 — Gerar o plano em lotes (NÃO altera código)

```
Com base em docs/AUDITORIA.md, gere um plano de correção em lotes pequenos e
salve como docs/PLANO.md. Cada lote deve ser testável isoladamente com
`flutter run` no meu S25 Ultra. Ordene do mais seguro (débitos técnicos e
layout) para o mais complexo (integrações de câmera, OCR e smartwatch).
Não escreva código ainda. Me mostre o PLANO.md ao final.
```

---

## PROMPT 4 — Executar UM lote de cada vez (modelo, ajuste o número)

```
Execute APENAS o Lote 1 do docs/PLANO.md. Não avance para o próximo lote.
Ao terminar, deixe o app pronto para eu rodar com `flutter run` e me diga
exatamente o que devo olhar na tela do S25 para validar este lote.
```

Depois de testar e aprovar, repita trocando "Lote 1" por "Lote 2", e assim por diante.

---

## PROMPT 5 — Rodar o app com Hot Reload

```
Rode `flutter run` no meu S25 Ultra.
```

Com o app aberto, aperte `r` no terminal a cada mudança para recarregar em ~1s.

---

## PROMPT 6 — Gerar o APK (só no final de um bloco grande)

```
Gere um APK de teste (debug) para eu instalar no S25 Ultra e me diga o
caminho do arquivo .apk gerado.
```
