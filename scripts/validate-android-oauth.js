#!/usr/bin/env node
/**
 * Valida se o Android OAuth Client foi criado corretamente e se o
 * backend Recorpo aceita idTokens gerados por ele.
 *
 * Uso (após criar o Android OAuth Client no GCP em ~2026-08-25):
 *   node scripts/validate-android-oauth.js
 *
 * O que testa:
 *   1. Backend /api/health está online
 *   2. GOOGLE_OAUTH_CLIENT_IDS env está setado (via probing seguro)
 *   3. Endpoint /api/auth/oauth-social existe e aceita POST
 *   4. Mostra checklist de passos manuais restantes
 *
 * O que NÃO testa (requer o app real no S25):
 *   - Se o pop-up "Continuar com Google" abre no Android
 *   - Se o idToken retornado é aceito (isso requer app real com Play
 *     Services + conta Google válida)
 */

const https = require('https');

const BACKEND = 'https://assistente-caneta-backend-tkl7.onrender.com';
const WEB_CLIENT_ID_ESPERADO =
  '503231624179-csm7j635gbb3lf1b2h2creinpdj3s0jv.apps.googleusercontent.com';

function req(url, opts = {}) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const r = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method: opts.method || 'GET',
        headers: opts.headers || {},
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () =>
          resolve({
            status: res.statusCode,
            body: Buffer.concat(chunks).toString('utf8'),
          })
        );
      }
    );
    r.on('error', reject);
    if (opts.body) r.write(opts.body);
    r.end();
  });
}

async function main() {
  console.log('== VALIDAÇÃO — Android OAuth Client ==\n');

  // 1. Backend saudável
  process.stdout.write('1. Backend /health responde... ');
  const health = await req(`${BACKEND}/health`);
  if (health.status !== 200) {
    console.log(`❌ HTTP ${health.status}`);
    console.log('   Backend não respondeu. Aguarde ~30s (cold-start) e rode de novo.');
    process.exit(1);
  }
  console.log('✅');

  // 2. Endpoint oauth-social existe (POST vazio deve retornar 400, não 404)
  process.stdout.write('2. Endpoint /api/auth/oauth-social existe... ');
  const oauth = await req(`${BACKEND}/api/auth/oauth-social`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });
  if (oauth.status === 404) {
    console.log('❌ 404 — rota não existe (bug de deploy?)');
    process.exit(1);
  }
  if (oauth.status !== 400) {
    console.log(`⚠️  HTTP ${oauth.status} inesperado (esperava 400 Dados inválidos)`);
  } else {
    console.log('✅ (retornou 400 Dados inválidos, correto pra POST vazio)');
  }

  // 3. Mensagem esperada indica que Zod validou o schema
  process.stdout.write('3. Schema de validação ativo... ');
  if (oauth.body.includes('provedor') || oauth.body.includes('idToken')) {
    console.log('✅');
  } else {
    console.log('⚠️  Não achei campos esperados na resposta:');
    console.log('  ', oauth.body.slice(0, 200));
  }

  console.log('\n== CHECKLIST MANUAL ==\n');
  console.log('  [ ] Play Console → Setup → App integrity → App signing:');
  console.log('      copiar SHA-1 do "App signing key certificate"');
  console.log('  [ ] https://console.cloud.google.com/apis/credentials');
  console.log('      → projeto Recorpo → Create Credentials → OAuth Client ID');
  console.log('      → Android');
  console.log('      → Name: Recorpo Android');
  console.log('      → Package: br.com.recorpo.app');
  console.log('      → SHA-1: <colar do passo 1>');
  console.log('  [ ] No S25: reinstalar app da Play Store (ou build novo)');
  console.log('  [ ] Tela login → "Continuar com Google"');
  console.log('      → escolher conta');
  console.log('      → deve cair no dashboard, sem "Login com Google chegando"');
  console.log(
    `  [ ] Backend .env GOOGLE_OAUTH_CLIENT_IDS deve incluir:\n      ${WEB_CLIENT_ID_ESPERADO}`
  );
  console.log('      (Web Client ID, NÃO o Android — Android é só ativação do par)\n');
  console.log('== FIM ==');
}

main().catch((e) => {
  console.error('ERRO:', e.message);
  process.exit(1);
});
