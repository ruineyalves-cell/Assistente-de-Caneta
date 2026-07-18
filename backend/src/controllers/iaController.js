const { z } = require('zod');

/**
 * Lote 21 — Análise de refeição por IA de visão.
 *
 * Contrato do endpoint POST /api/ia/refeicao
 *   Entrada: { imagemBase64: string (JPEG/PNG codificado sem prefix data:) }
 *   Saída (sucesso):
 *     { titulo, descricao, proteinaEstimadaG, aguaEstimadaMl, confianca }
 *   Saída (sem chave configurada):
 *     { iaConfigurada: false, mensagem: '...' }  → app cai no fallback local
 *
 * Estratégia:
 *   - Se `GEMINI_API_KEY` estiver setada, usa Gemini 1.5 Flash (grátis
 *     no free tier do Google AI Studio; melhor custo/benefício).
 *   - Se `OPENAI_API_KEY` estiver setada, usa gpt-4o-mini (pago mas
 *     barato).
 *   - Se nada estiver setado, devolve `iaConfigurada:false` — não é
 *     erro: o Flutter cai pro ML Kit local sem alerta ruim.
 */
const schema = z.object({
  imagemBase64: z.string().min(100).max(20 * 1024 * 1024), // até ~15 MB base64
});

async function analisar(req, res, next) {
  try {
    const { imagemBase64 } = schema.parse(req.body);
    const geminiKey = process.env.GEMINI_API_KEY;
    const openaiKey = process.env.OPENAI_API_KEY;

    if (!geminiKey && !openaiKey) {
      return res.json({
        iaConfigurada: false,
        mensagem:
          'Análise por IA ainda não ativada no servidor. O reconhecimento local segue funcionando.',
      });
    }

    if (geminiKey) {
      return await _analisarComGemini(imagemBase64, geminiKey, res);
    }
    return await _analisarComOpenAI(imagemBase64, openaiKey, res);
  } catch (err) {
    next(err);
  }
}

// ============================================================================
// Gemini 1.5 Flash — melhor custo/benefício para foto
// ============================================================================
async function _analisarComGemini(imagemBase64, apiKey, res) {
  const url =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=' +
    encodeURIComponent(apiKey);

  const body = {
    contents: [
      {
        parts: [
          { text: _prompt() },
          {
            inline_data: {
              mime_type: 'image/jpeg',
              data: imagemBase64,
            },
          },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.2,
    },
  };

  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!r.ok) {
    return res.status(502).json({
      erro: 'Falha ao consultar a IA. Tente novamente em instantes.',
      status: r.status,
    });
  }
  const data = await r.json();
  const texto = data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
  return res.json(_normalizar(_parseJsonSeguro(texto)));
}

// ============================================================================
// OpenAI gpt-4o-mini — alternativa paga com boa acurácia
// ============================================================================
async function _analisarComOpenAI(imagemBase64, apiKey, res) {
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
            { type: 'text', text: _prompt() },
            {
              type: 'image_url',
              image_url: { url: `data:image/jpeg;base64,${imagemBase64}` },
            },
          ],
        },
      ],
    }),
  });
  if (!r.ok) {
    return res.status(502).json({
      erro: 'Falha ao consultar a IA. Tente novamente em instantes.',
      status: r.status,
    });
  }
  const data = await r.json();
  const texto = data?.choices?.[0]?.message?.content || '{}';
  return res.json(_normalizar(_parseJsonSeguro(texto)));
}

function _prompt() {
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

function _normalizar(j) {
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

module.exports = { analisar };
