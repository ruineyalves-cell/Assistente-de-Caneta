# Recorpo — Kit de publicação Google Play

Pasta com todos os assets visuais + textos oficiais + roteiros necessários
para publicar o Recorpo na Google Play Store Brasil.

## Estrutura

```
docs/play-store/
├── COPY.md                              — Textos oficiais (nome, descrições, keywords)
├── ROTEIRO_VIDEO_30S.md                 — Storyboard e roteiro do vídeo promo
├── README.md                            — este arquivo
└── assets/
    ├── icon-512.svg                     — Ícone quadrado 512×512 (fallback)
    ├── icon-adaptive-foreground.svg     — Foreground do adaptive icon Android
    ├── icon-adaptive-background.svg     — Background do adaptive icon Android
    ├── feature-graphic-1024x500.svg     — Banner topo da listing
    ├── screenshot-1-boas-vindas.svg     — Screenshot 1 (1080×1920)
    ├── screenshot-2-dashboard.svg       — Screenshot 2 (1080×1920)
    ├── screenshot-3-lembrete-dose.svg   — Screenshot 3 (1080×1920)
    ├── screenshot-4-sintomas.svg        — Screenshot 4 (1080×1920)
    └── screenshot-5-pdf-medico.svg      — Screenshot 5 (1080×1920)
```

## Como converter SVG → PNG

A Play Store exige PNG ou JPG. Todos os assets aqui são SVG editáveis
(fonte da verdade). Escolha o método:

### Opção A — Inkscape (recomendado)

Preserva melhor gradientes e filtros complexos.

```bash
# Instalar Inkscape (Windows): winget install Inkscape.Inkscape
# ou baixar em https://inkscape.org

# Converter todos os assets de uma vez:
cd docs/play-store/assets

for svg in *.svg; do
  inkscape "$svg" \
    --export-type=png \
    --export-filename="${svg%.svg}.png"
done
```

### Opção B — Chrome/Chromium headless

Sem instalação extra se você já tem Chrome.

```bash
# Um arquivo específico:
chrome --headless --disable-gpu --screenshot=icon-512.png \
  --window-size=512,512 \
  file://$(pwd)/icon-512.svg
```

### Opção C — Online (mais rápido)

https://cloudconvert.com/svg-to-png — configurar largura conforme a
dimensão nativa de cada SVG (viewBox). Não use compressão.

## Onde entra cada arquivo no Play Console

| Play Console                           | Arquivo                            | Dimensão              |
| -------------------------------------- | ---------------------------------- | --------------------- |
| **Ícone do app**                       | `icon-512.png`                     | 512 × 512 (PNG, 32-bit) |
| **Adaptive icon** (via Android Studio) | `icon-adaptive-*.png`              | 512 × 512             |
| **Gráfico de destaque** (feature)      | `feature-graphic-1024x500.png`     | 1024 × 500 (JPG/PNG, sem alpha) |
| **Screenshots — celular**              | `screenshot-1..5.png`              | 1080 × 1920           |
| **Vídeo promo** (opcional)             | `roteiro-video.mp4` (ver roteiro)  | YouTube link          |

**Importante:** o feature graphic **não pode ter transparência**. Se
usar Inkscape, ele já exporta com fundo. Se for outro conversor,
configure `background: #070E1A` no comando.

## Copy oficial

Todos os textos (nome, descrição curta, descrição completa, palavras-chave)
estão em [`COPY.md`](./COPY.md). Copie e cole direto no Play Console — foi
escrito no limite de caracteres com folga proposital para futuros ajustes.

## Vídeo promo (opcional, mas potente)

O roteiro storyboard de 30 segundos está em [`ROTEIRO_VIDEO_30S.md`](./ROTEIRO_VIDEO_30S.md).

Não precisa produzir profissionalmente para lançar — mas apps de saúde
com vídeo têm **~35% mais conversão** de visualização → instalação, então
vale a pena mesmo que gravado com CapCut ou similar.

## Checklist antes de publicar

- [ ] Todos os SVGs convertidos para PNG (ou JPG no caso do feature graphic).
- [ ] Ícone 512×512 sem transparência no fundo.
- [ ] Feature graphic sem canal alfa.
- [ ] Screenshots com pelo menos 4 (temos 5 — usar todos).
- [ ] Descrição curta ≤ 80 caracteres (a nossa: 76).
- [ ] Descrição completa ≤ 4000 caracteres (a nossa: ~3400).
- [ ] Política de privacidade hospedada em URL pública → **usar
      https://recorpo.com.br/privacidade** quando o domínio estiver de pé.
- [ ] Email de contato configurado — **contato@recorpo.com.br**.
- [ ] Categoria: **Saúde e fitness**.
- [ ] Faixa etária: Todos, com aviso de conteúdo médico.
- [ ] Anúncios: Não.
- [ ] Compras no app: Sim (Premium R$ 19,90/mês).
