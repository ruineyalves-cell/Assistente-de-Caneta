/**
 * Seção "Câmera com IA" — o diferencial de captura e análise por imagem:
 * Prato, Rótulo, Bula e Receita. Mockup do scanner em componente (SVG + CSS),
 * cópia com isca pra baixar o app e ponte pro acompanhamento médico.
 */
const CAPS = [
  {
    tag: 'Prato',
    color: 'text-eixo-refeicao',
    ring: 'border-eixo-refeicao/40',
    tint: 'bg-eixo-refeicao/12',
    emoji: '🍽️',
    body: 'Estima a proteína e as calorias da refeição e sugere ajustes que respeitam a sua saciedade GLP-1.',
  },
  {
    tag: 'Rótulo',
    color: 'text-eixo-agua',
    ring: 'border-eixo-agua/40',
    tint: 'bg-eixo-agua/12',
    emoji: '🏷️',
    body: 'Lê a tabela nutricional e destaca o que importa — proteína, açúcares e porção real.',
  },
  {
    tag: 'Bula',
    color: 'text-brand-primaryLight',
    ring: 'border-brand-primaryLight/40',
    tint: 'bg-brand-primary/15',
    emoji: '📄',
    body: 'Resume posologia e efeitos da sua caneta em linguagem clara, com base em bulas oficiais (Anvisa).',
  },
  {
    tag: 'Receita',
    color: 'text-eixo-peso',
    ring: 'border-eixo-peso/40',
    tint: 'bg-eixo-peso/12',
    emoji: '🩺',
    body: 'Reconhece a medicação e a dose prescritas e já deixa seu perfil configurado — sem digitar.',
  },
];

export default function AiCapture() {
  return (
    <div>
      <div className="text-center max-w-2xl mx-auto mb-14">
        <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-3">
          Diferencial · Câmera com IA
        </p>
        <h2 className="font-serif text-4xl md:text-5xl text-recorpo-text">
          Aponte a câmera.{' '}
          <span className="italic bg-primary-gradient bg-clip-text text-transparent">
            O Recorpo entende
          </span>{' '}
          o resto.
        </h2>
        <p className="mt-4 text-recorpo-dim">
          Prato, rótulo, bula ou receita: uma foto vira dado organizado no seu
          histórico. Menos digitação, mais adesão — e a informação certa na hora
          da consulta.
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-12 items-center">
        {/* Scanner mockup */}
        <div className="relative flex items-center justify-center min-h-[380px]">
          <div
            aria-hidden
            className="absolute inset-0 flex items-center justify-center pointer-events-none"
          >
            <div className="w-[320px] h-[320px] rounded-full bg-eixo-refeicao/15 blur-[110px] animate-pulseSoft" />
          </div>

          <div className="relative z-10 w-[260px] aspect-[9/17] rounded-[38px] bg-[#0A0F1B] p-2 border border-white/[0.08] shadow-[0_40px_90px_-30px_rgba(0,0,0,0.9)] animate-hero-float">
            <div className="relative w-full h-full rounded-[30px] overflow-hidden bg-recorpo-bg">
              {/* "câmera" — cena do prato */}
              <div className="absolute inset-0 bg-gradient-to-b from-[#1a2338] to-[#0B1220]" />
              <div className="absolute top-1/3 left-1/2 -translate-x-1/2 text-6xl">
                🍽️
              </div>

              {/* Moldura de mira */}
              <div className="absolute inset-6 rounded-2xl border-2 border-brand-primaryLight/70">
                <Corner className="top-0 left-0" />
                <Corner className="top-0 right-0 rotate-90" />
                <Corner className="bottom-0 right-0 rotate-180" />
                <Corner className="bottom-0 left-0 -rotate-90" />
                {/* linha de varredura */}
                <div className="absolute left-0 right-0 h-[2px] bg-brand-primaryLight/80 shadow-glow animate-scanline" />
              </div>

              {/* Chip de resultado */}
              <div className="absolute bottom-6 left-1/2 -translate-x-1/2 w-[86%] rounded-2xl bg-recorpo-surface/95 backdrop-blur-md border border-eixo-refeicao/30 px-3 py-2.5">
                <div className="text-[9px] tracking-widest uppercase text-recorpo-muted">
                  Detectado
                </div>
                <div className="text-recorpo-text text-sm font-semibold">
                  Frango + arroz + salada
                </div>
                <div className="text-eixo-refeicao text-xs font-semibold mt-0.5">
                  ≈ 38 g de proteína
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Capacidades */}
        <div className="space-y-4">
          {CAPS.map((c) => (
            <div
              key={c.tag}
              className={`flex gap-4 rounded-2xl border ${c.ring} bg-recorpo-surface/60 backdrop-blur-md p-4`}
            >
              <div
                className={`w-11 h-11 flex-none rounded-xl ${c.tint} flex items-center justify-center text-xl`}
              >
                {c.emoji}
              </div>
              <div>
                <div className={`font-serif text-lg ${c.color}`}>{c.tag}</div>
                <p className="text-recorpo-dim text-sm leading-relaxed">
                  {c.body}
                </p>
              </div>
            </div>
          ))}

          <p className="text-xs text-recorpo-muted leading-relaxed pt-1">
            A IA de refeição faz parte do{' '}
            <span className="text-recorpo-dim font-medium">Premium</span>. Rótulo,
            bula e receita ajudam você a registrar mais rápido e a chegar na
            consulta com tudo em ordem.
          </p>
        </div>
      </div>
    </div>
  );
}

function Corner({ className = '' }: { className?: string }) {
  return (
    <span
      aria-hidden
      className={`absolute w-4 h-4 border-t-2 border-l-2 border-brand-primaryLight ${className}`}
    />
  );
}
