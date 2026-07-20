const { z } = require('zod');

/**
 * IA de visão — 3 endpoints, mesma engine.
 *
 * POST /api/ia/refeicao  (Lote 21) — analisa prato de comida
 * POST /api/ia/rotulo    (Lote 32.8) — tabela nutricional
 * POST /api/ia/bula      (Lote 32.8) — bula de medicamento
 *
 * Estratégia:
 *  - Se `GEMINI_API_KEY` estiver setada, usa Gemini 1.5 Flash.
 *  - Se `OPENAI_API_KEY` estiver setada, usa gpt-4o-mini.
 *  - Se nada estiver setado, devolve `iaConfigurada:false` — não é
 *    erro: o Flutter cai para fallback local (label ML Kit no caso
 *    da refeição; mensagem informativa nos outros).
 */
const schemaImagem = z.object({
  imagemBase64: z.string().min(100).max(20 * 1024 * 1024),
});

// ─────────────────────────────────────────────────────────────
// Prompts
// ─────────────────────────────────────────────────────────────
function _promptRefeicao() {
  return `Você é um assistente nutricional educacional em português brasileiro.
Analise a foto de uma refeição e responda APENAS com um JSON no formato:
{
  "titulo": "nome curto do prato (ex: 'Frango grelhado com salada')",
  "descricao": "descrição breve dos itens visíveis, 1-2 frases",
  "proteinaEstimadaG": <número inteiro estimado em gramas de proteína>,
  "aguaEstimadaMl": <número inteiro em ml da bebida visível OU 0>,
  "confianca": <0.0 a 1.0>
}
Regras:
- Não invente itens que não vê.
- Se não for uma refeição, retorne { "titulo": null, "descricao": "Imagem não parece uma refeição.", "proteinaEstimadaG": null, "aguaEstimadaMl": null, "confianca": 0.0 }
- Não escreva nada fora do JSON. Não use markdown.`;
}

function _promptRotulo() {
  return `Você é um leitor de rótulos alimentares em português brasileiro.
Analise a foto do rótulo/tabela nutricional e responda APENAS com um JSON:
{
  "produto": "nome do produto (se legível)",
  "porcao": "porção de referência conforme o rótulo (ex: '30 g' ou '200 ml')",
  "caloriasKcal": <número por porção>,
  "proteinaG": <número por porção>,
  "carboidratosG": <número por porção>,
  "gordurasG": <número por porção>,
  "gordurasSaturadasG": <número por porção>,
  "fibraG": <número por porção>,
  "sodioMg": <número por porção>,
  "confianca": <0.0 a 1.0>
}
Regras:
- Se o rótulo estiver ilegível ou não for uma tabela nutricional, retorne
  { "produto": null, "porcao": null, "confianca": 0.0 } e null nos macros.
- Use null (não zero) para campos ausentes.
- Não escreva nada fora do JSON. Não use markdown.`;
}

function _promptBula() {
  return `Você é um leitor de bulas de medicamento em português brasileiro.
Analise a foto/imagem da bula e responda APENAS com um JSON:
{
  "medicamento": "nome comercial se visível",
  "principioAtivo": "princípio ativo se visível",
  "indicacoes": ["lista curta de indicações principais"],
  "dose": "dosagem/frequência padrão como texto curto",
  "efeitosComuns": ["lista dos efeitos colaterais mais frequentes"],
  "alertas": ["contraindicações e advertências principais"],
  "confianca": <0.0 a 1.0>
}
Regras:
- APENAS transcreva o que está escrito na bula. Nunca invente ou
  interprete. Nunca sugira conduta clínica.
- Se a imagem não parecer uma bula, retorne todos campos null e
  confianca 0.0.
- Use listas vazias (não null) quando não conseguir extrair itens.
- Não escreva nada fora do JSON. Não use markdown.`;
}

// ─────────────────────────────────────────────────────────────
// Normalizadores
// ─────────────────────────────────────────────────────────────
function _normalizarRefeicao(j) {
  return {
    titulo: j.titulo || null,
    descricao: j.descricao || null,
    proteinaEstimadaG:
      typeof j.proteinaEstimadaG === 'number' ? Math.round(j.proteinaEstimadaG) : null,
    aguaEstimadaMl:
      typeof j.aguaEstimadaMl === 'number' ? Math.round(j.aguaEstimadaMl) : null,
    confianca: typeof j.confianca === 'number' ? j.confianca : 0.5,
  };
}

function _num(v) {
  return typeof v === 'number' && Number.isFinite(v) ? v : null;
}

function _normalizarRotulo(j) {
  return {
    produto: j.produto || null,
    porcao: j.porcao || null,
    caloriasKcal: _num(j.caloriasKcal),
    proteinaG: _num(j.proteinaG),
    carboidratosG: _num(j.carboidratosG),
    gordurasG: _num(j.gordurasG),
    gordurasSaturadasG: _num(j.gordurasSaturadasG),
    fibraG: _num(j.fibraG),
    sodioMg: _num(j.sodioMg),
    confianca: typeof j.confianca === 'number' ? j.confianca : 0.5,
  };
}

function _listaStr(v) {
  return Array.isArray(v) ? v.filter((x) => typeof x === 'string' && x.trim()) : [];
}

function _normalizarBula(j) {
  return {
    medicamento: j.medicamento || null,
    principioAtivo: j.principioAtivo || null,
    indicacoes: _listaStr(j.indicacoes),
    dose: j.dose || null,
    efeitosComuns: _listaStr(j.efeitosComuns),
    alertas: _listaStr(j.alertas),
    confianca: typeof j.confianca === 'number' ? j.confianca : 0.5,
  };
}

// ─────────────────────────────────────────────────────────────
// Motor de análise — chamada HTTP
// ─────────────────────────────────────────────────────────────
async function _chamarGemini(imagemBase64, prompt, apiKey) {
  const url =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=' +
    encodeURIComponent(apiKey);
  const body = {
    contents: [
      {
        parts: [
          { text: prompt },
          { inline_data: { mime_type: 'image/jpeg', data: imagemBase64 } },
        ],
      },
    ],
    generationConfig: { responseMimeType: 'application/json', temperature: 0.2 },
  };
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!r.ok) throw new Error(`Gemini ${r.status}`);
  const data = await r.json();
  return data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
}

async function _chamarOpenAI(imagemBase64, prompt, apiKey) {
  const r = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      temperature: 0.2,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            {
              type: 'image_url',
              image_url: { url: `data:image/jpeg;base64,${imagemBase64}` },
            },
          ],
        },
      ],
    }),
  });
  if (!r.ok) throw new Error(`OpenAI ${r.status}`);
  const data = await r.json();
  return data?.choices?.[0]?.message?.content || '{}';
}

function _parseJsonSeguro(texto) {
  try {
    return JSON.parse(texto);
  } catch (_) {
    const inicio = texto.indexOf('{');
    const fim = texto.lastIndexOf('}');
    if (inicio >= 0 && fim > inicio) {
      try {
        return JSON.parse(texto.slice(inicio, fim + 1));
      } catch (_) {}
    }
    return {};
  }
}

async function _analisar({ imagemBase64, prompt, normalizar }) {
  const geminiKey = process.env.GEMINI_API_KEY;
  const openaiKey = process.env.OPENAI_API_KEY;
  if (!geminiKey && !openaiKey) {
    return {
      iaConfigurada: false,
      mensagem:
        'Análise por IA ainda não ativada no servidor. Configure GEMINI_API_KEY.',
    };
  }
  const texto = geminiKey
    ? await _chamarGemini(imagemBase64, prompt, geminiKey)
    : await _chamarOpenAI(imagemBase64, prompt, openaiKey);
  return { iaConfigurada: true, ...normalizar(_parseJsonSeguro(texto)) };
}

// ─────────────────────────────────────────────────────────────
// Handlers públicos
// ─────────────────────────────────────────────────────────────
async function analisar(req, res, next) {
  try {
    const { imagemBase64 } = schemaImagem.parse(req.body);
    const r = await _analisar({
      imagemBase64,
      prompt: _promptRefeicao(),
      normalizar: _normalizarRefeicao,
    });
    return res.json(r);
  } catch (err) {
    if (String(err.message).match(/Gemini|OpenAI/)) {
      return res.status(502).json({
        erro: 'Falha ao consultar a IA. Tente novamente em instantes.',
      });
    }
    next(err);
  }
}

async function analisarRotulo(req, res, next) {
  try {
    const { imagemBase64 } = schemaImagem.parse(req.body);
    const r = await _analisar({
      imagemBase64,
      prompt: _promptRotulo(),
      normalizar: _normalizarRotulo,
    });
    return res.json(r);
  } catch (err) {
    if (String(err.message).match(/Gemini|OpenAI/)) {
      return res.status(502).json({
        erro: 'Falha ao consultar a IA. Tente novamente em instantes.',
      });
    }
    next(err);
  }
}

async function analisarBula(req, res, next) {
  try {
    const { imagemBase64 } = schemaImagem.parse(req.body);
    const r = await _analisar({
      imagemBase64,
      prompt: _promptBula(),
      normalizar: _normalizarBula,
    });
    return res.json(r);
  } catch (err) {
    if (String(err.message).match(/Gemini|OpenAI/)) {
      return res.status(502).json({
        erro: 'Falha ao consultar a IA. Tente novamente em instantes.',
      });
    }
    next(err);
  }
}

// Exporta normalizadores para testes unit; não usados por outros
// módulos em runtime.
module.exports = {
  analisar,
  analisarRotulo,
  analisarBula,
  _normalizarRotulo,
  _normalizarBula,
  _normalizarRefeicao,
  _parseJsonSeguro,
};
