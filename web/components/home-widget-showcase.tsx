/**
 * Seção do Widget de tela inicial "Recorpo Hoje".
 *
 * Mockup 100% em componente (SVG + CSS), como o HeroDashboard — nada de
 * screenshot. Espelha o widget real do app (anéis Proteína + Água, Score no
 * centro, streak e atalhos +250/+500). Só mostra dados NÃO sensíveis; peso e
 * sintomas ficam dentro do app (mensagem reforçada na cópia, alinhada à LGPD).
 */
export default function HomeWidgetShowcase() {
  return (
    <div className="grid md:grid-cols-2 gap-12 items-center">
      {/* Texto */}
      <div>
        <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-3">
          Novo · Widget de tela inicial
        </p>
        <h2 className="font-serif text-4xl md:text-5xl text-recorpo-text leading-[1.05]">
          Seu dia num relance —{' '}
          <span className="italic bg-primary-gradient bg-clip-text text-transparent">
            sem nem abrir
          </span>{' '}
          o app.
        </h2>
        <p className="mt-5 text-recorpo-dim text-lg leading-relaxed">
          O widget <strong className="text-recorpo-text">Recorpo Hoje</strong>{' '}
          fica na sua tela inicial mostrando o essencial: proteína e água em
          anéis, seu Score do dia no centro e a sua sequência de dias. Um toque
          em <span className="text-eixo-agua font-semibold">+250</span> ou{' '}
          <span className="text-eixo-agua font-semibold">+500&nbsp;ml</span>{' '}
          registra hidratação na hora.
        </p>

        <ul className="mt-7 space-y-3">
          <Feature
            color="text-eixo-peso"
            title="Panorama instantâneo"
            body="Score, proteína e água num olhar — a consistência que o tratamento pede, sempre à vista."
          />
          <Feature
            color="text-eixo-agua"
            title="Água em 1 toque"
            body="+250 e +500 ml direto da home. Sem abrir o app, sem sede acumulada."
          />
          <Feature
            color="text-brand-primaryLight"
            title="Privado por padrão"
            body="Peso e sintomas nunca aparecem no widget — dado sensível fica dentro do app, protegido pela sua biometria."
          />
        </ul>

        <div className="mt-8">
          <a
            href="#baixar"
            className="inline-flex items-center gap-2 font-semibold px-6 py-3.5 rounded-full bg-primary-gradient text-white shadow-glowSoft hover:-translate-y-0.5 transition-transform"
          >
            Quero na minha tela
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path
                d="M5 12h14M13 6l6 6-6 6"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </a>
        </div>
      </div>

      {/* Mockup do widget */}
      <div className="relative flex items-center justify-center min-h-[360px]">
        <div
          aria-hidden
          className="absolute inset-0 flex items-center justify-center pointer-events-none"
        >
          <div className="w-[340px] h-[340px] rounded-full bg-brand-primary/20 blur-[110px] animate-pulseSoft" />
        </div>

        <div className="relative z-10 w-[330px] rounded-[28px] bg-recorpo-surface/95 backdrop-blur-md border border-white/[0.08] shadow-2xl shadow-black/60 p-5 animate-hero-float">
          {/* Topo */}
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <span className="w-4 h-4 rounded-[5px] bg-primary-gradient" />
              <span className="text-sm font-semibold text-recorpo-text">
                Recorpo · Hoje
              </span>
            </div>
            <span className="text-xs font-semibold text-eixo-streak">
              🔥 12 dias
            </span>
          </div>

          {/* Corpo: anéis + stats */}
          <div className="flex items-center gap-4">
            <div className="relative w-[118px] h-[118px] flex-none">
              <svg viewBox="0 0 150 150" width="118" height="118">
                <g transform="rotate(-90 75 75)">
                  <circle cx="75" cy="75" r="60" fill="none" stroke="#22304D" strokeWidth="11" />
                  <circle
                    cx="75"
                    cy="75"
                    r="60"
                    fill="none"
                    stroke="#E27D3F"
                    strokeWidth="11"
                    strokeLinecap="round"
                    strokeDasharray="377"
                    strokeDashoffset="117"
                  />
                  <circle cx="75" cy="75" r="45" fill="none" stroke="#22304D" strokeWidth="11" />
                  <circle
                    cx="75"
                    cy="75"
                    r="45"
                    fill="none"
                    stroke="#3DB5C6"
                    strokeWidth="11"
                    strokeLinecap="round"
                    strokeDasharray="283"
                    strokeDashoffset="147"
                  />
                </g>
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-[10px] text-recorpo-muted">Score</span>
                <span className="text-2xl font-extrabold text-eixo-peso leading-none">
                  78%
                </span>
              </div>
            </div>

            <div className="flex-1 space-y-2.5">
              <Stat emoji="🍊" tint="bg-eixo-refeicao/15" label="Proteína" value="96 / 140 g" />
              <Stat emoji="💧" tint="bg-eixo-agua/15" label="Água" value="48% · 1,4 L" />
              <Stat emoji="⚖️" tint="bg-eixo-peso/15" label="Peso" value="no app 🔒" />
            </div>
          </div>

          {/* Atalhos de água */}
          <div className="mt-4 grid grid-cols-2 gap-2">
            {['+250', '+500'].map((v) => (
              <div
                key={v}
                className="rounded-2xl border border-eixo-agua/40 bg-eixo-agua/10 py-2.5 text-center"
              >
                <div className="text-sm font-extrabold text-eixo-agua">{v}</div>
                <div className="text-[10px] text-recorpo-muted">ml de água</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Feature({
  color,
  title,
  body,
}: {
  color: string;
  title: string;
  body: string;
}) {
  return (
    <li className="flex gap-3">
      <span className={`mt-1 flex-none ${color}`} aria-hidden>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path
            d="M20 6L9 17l-5-5"
            stroke="currentColor"
            strokeWidth="2.4"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </span>
      <div>
        <div className="text-recorpo-text font-semibold text-sm">{title}</div>
        <div className="text-recorpo-dim text-sm leading-relaxed">{body}</div>
      </div>
    </li>
  );
}

function Stat({
  emoji,
  tint,
  label,
  value,
}: {
  emoji: string;
  tint: string;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-center gap-2.5">
      <span
        className={`w-7 h-7 rounded-lg ${tint} flex items-center justify-center text-sm flex-none`}
      >
        {emoji}
      </span>
      <div className="min-w-0">
        <div className="text-recorpo-text font-semibold text-[13px] leading-tight">
          {label}
        </div>
        <div className="text-recorpo-muted text-[11px] leading-tight">
          {value}
        </div>
      </div>
    </div>
  );
}
