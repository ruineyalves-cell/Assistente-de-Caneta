#!/usr/bin/env node
/**
 * build-play-store-assets.mjs — Lote G4
 *
 * Converte os SVGs em docs/play-store/assets/ para PNG nos tamanhos
 * exigidos pelo Google Play Console:
 *
 *   Ícone da loja      → 512×512 PNG
 *   Feature graphic    → 1024×500 PNG
 *   Screenshots        → 1080×1920 PNG (5 imagens)
 *   Adaptive icon      → 432×432 PNG (foreground + background)
 *
 * Saída em docs/play-store/assets/out/ — pronto pra upload no Console.
 *
 * Requisitos:
 *   npm install --no-save sharp
 *
 * Uso:
 *   node scripts/build-play-store-assets.mjs
 */
import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';
import { join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(fileURLToPath(new URL('.', import.meta.url)), '..');
const IN = join(ROOT, 'docs', 'play-store', 'assets');
const OUT = join(IN, 'out');
// Screenshots do site (Lote I3): geradas em `web/public/screenshots/`
// pra o next/image otimizar (WebP/AVIF, srcset, lazy, blur placeholder).
// Sem essa cópia, o site precisaria de dangerouslyAllowSVG no Next config
// (menos seguro; SVG pode conter JS/CSS injetado).
const OUT_WEB_SCREENSHOTS = join(ROOT, 'web', 'public', 'screenshots');

// Mapa: padrão do arquivo → { largura, altura, [subpasta] }
const REGRAS = [
  { match: /^icon-512\.svg$/, w: 512, h: 512, out: 'icon-512.png' },
  { match: /^feature-graphic-1024x500\.svg$/, w: 1024, h: 500, out: 'feature-graphic-1024x500.png' },
  // Screenshots geram DUAS versões: Play Console (1080x1920 PNG) e site
  // (mesmo tamanho, mas destino diferente). Site fica commitado; Play
  // Store fica no /out/ (gitignored, gerado sob demanda).
  { match: /^screenshot-.*\.svg$/, w: 1080, h: 1920, alsoWeb: true },
  { match: /^icon-adaptive-background\.svg$/, w: 432, h: 432, out: 'icon-adaptive-background.png' },
  { match: /^icon-adaptive-foreground\.svg$/, w: 432, h: 432, out: 'icon-adaptive-foreground.png' },
];

async function main() {
  let sharp;
  try {
    ({ default: sharp } = await import('sharp'));
  } catch {
    console.error(
      '\n❌ sharp não instalado. Rode:\n   npm install --no-save sharp\n' +
        'e execute este script novamente.\n'
    );
    process.exit(1);
  }

  await mkdir(OUT, { recursive: true });
  await mkdir(OUT_WEB_SCREENSHOTS, { recursive: true });
  const arquivos = (await readdir(IN)).filter((f) => f.endsWith('.svg'));
  let convertidos = 0;

  for (const f of arquivos) {
    const regra = REGRAS.find((r) => r.match.test(f));
    if (!regra) {
      console.warn(`[skip] ${f} — nenhuma regra de conversão definida`);
      continue;
    }
    const svg = await readFile(join(IN, f));
    const nomePng = regra.out || basename(f, '.svg') + '.png';

    // Renderiza UMA vez o buffer PNG e escreve em N destinos — 3x mais
    // rápido que rodar sharp() duas vezes com mesmo input.
    const buffer = await sharp(svg, { density: 300 })
      .resize(regra.w, regra.h, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png({ compressionLevel: 9 })
      .toBuffer();

    const destinos = [join(OUT, nomePng)];
    if (regra.alsoWeb) destinos.push(join(OUT_WEB_SCREENSHOTS, nomePng));

    for (const destino of destinos) {
      await writeFile(destino, buffer);
      console.log(`✓ ${f} → ${destino.replace(ROOT, '.')} (${regra.w}×${regra.h})`);
    }
    convertidos++;
  }

  console.log(`\n${convertidos} arquivo(s) convertido(s).`);
  console.log('- Play Console: docs/play-store/assets/out/');
  console.log('- Site (next/image): web/public/screenshots/');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
