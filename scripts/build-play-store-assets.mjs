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

// Mapa: padrão do arquivo → { largura, altura, [subpasta] }
const REGRAS = [
  { match: /^icon-512\.svg$/, w: 512, h: 512, out: 'icon-512.png' },
  { match: /^feature-graphic-1024x500\.svg$/, w: 1024, h: 500, out: 'feature-graphic-1024x500.png' },
  { match: /^screenshot-.*\.svg$/, w: 1080, h: 1920 },
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
    const destino = join(OUT, nomePng);
    await sharp(svg, { density: 300 })
      .resize(regra.w, regra.h, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png({ compressionLevel: 9 })
      .toFile(destino);
    console.log(`✓ ${f} → out/${nomePng} (${regra.w}×${regra.h})`);
    convertidos++;
  }

  console.log(`\n${convertidos} arquivo(s) convertido(s) em ${OUT}`);
  console.log('Pronto pra subir no Play Console → Presença na loja → Ficha da loja principal.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
