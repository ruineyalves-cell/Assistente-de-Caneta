/**
 * Hero da landing — mockup de celular flutuando com o Dashboard estilizado.
 * Micro-animações CSS: barra de água enchendo, mini-gráfico do peso desenhando,
 * halo pulsando. Sem JS runtime: tudo via CSS keyframes.
 */
export default function HeroDashboard() {
  return (
    <div className="relative w-full h-[520px] md:h-[600px] flex items-center justify-center">
      {/* Halo por trás do celular */}
      <div
        aria-hidden
        className="absolute inset-0 flex items-center justify-center pointer-events-none"
      >
        <div className="w-[380px] h-[380px] md:w-[500px] md:h-[500px] rounded-full bg-brand-primary/25 blur-[110px] animate-pulseSoft" />
      </div>

      {/* Cartão auxiliar esquerdo — "Próxima dose" */}
      <div
        className="hidden md:flex absolute left-2 top-16 z-20 rounded-2xl bg-recorpo-surface/90 backdrop-blur-md border border-white/10 px-4 py-3 shadow-2xl shadow-black/50 items-center gap-3 animate-hero-floatSlow"
        style={{ transform: 'rotate(-4deg)' }}
      >
        <div className="w-9 h-9 rounded-full bg-primary-gradient flex items-center justify-center">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path
              d="M12 8v4l3 2M12 22a10 10 0 110-20 10 10 0 010 20z"
              stroke="white"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </svg>
        </div>
        <div>
          <div className="text-[10px] tracking-widest uppercase text-recorpo-muted">
            Próxima dose
          </div>
          <div className="text-sm text-recorpo-text font-semibold">
            Quinta · 20h00
          </div>
        </div>
      </div>

      {/* Cartão auxiliar direito — "Água hoje" */}
      <div
        className="hidden md:flex absolute right-4 bottom-24 z-20 rounded-2xl bg-recorpo-surface/90 backdrop-blur-md border border-white/10 px-4 py-3 shadow-2xl shadow-black/50 items-center gap-3 animate-hero-floatFast"
        style={{ transform: 'rotate(5deg)' }}
      >
        <div className="relative w-9 h-9">
          <svg width="36" height="36" viewBox="0 0 36 36">
            <circle
              cx="18"
              cy="18"
              r="14"
              fill="none"
              stroke="rgba(61,181,198,0.2)"
              strokeWidth="3"
            />
            <circle
              cx="18"
              cy="18"
              r="14"
              fill="none"
              stroke="#3DB5C6"
              strokeWidth="3"
              strokeLinecap="round"
              strokeDasharray="88"
              className="animate-hero-water"
              transform="rotate(-90 18 18)"
            />
          </svg>
        </div>
        <div>
          <div className="text-[10px] tracking-widest uppercase text-recorpo-muted">
            Água hoje
          </div>
          <div className="text-sm text-recorpo-text font-semibold">
            <span className="tabular-nums">1,8</span> / 2,3 L
          </div>
        </div>
      </div>

      {/* Celular — moldura estilo device com Dashboard SVG dentro */}
      <div
        className="relative z-10 animate-hero-float"
        style={{ perspective: 1400 }}
      >
        <div
          className="relative w-[280px] md:w-[330px] aspect-[9/19] rounded-[42px] bg-[#0A0F1B] p-2 shadow-[0_50px_100px_-30px_rgba(0,0,0,0.9),0_20px_40px_-15px_rgba(74,144,217,0.35)] border border-white/[0.08]"
          style={{ transform: 'rotateY(-8deg) rotateX(4deg)' }}
        >
          {/* Tela */}
          <div className="relative w-full h-full rounded-[34px] overflow-hidden bg-recorpo-bg">
            {/* Notch */}
            <div
              aria-hidden
              className="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-6 bg-black rounded-full z-30"
            />
            {/* Reflexo diagonal */}
            <div
              aria-hidden
              className="absolute inset-0 pointer-events-none bg-gradient-to-tr from-transparent via-white/[0.05] to-transparent z-40"
            />

            {/* Conteúdo do Dashboard (SVG estilizado) */}
            <DashboardArt />
          </div>
        </div>
      </div>
    </div>
  );
}

/** Composição SVG que imita o Dashboard do app — com micro-animações. */
function DashboardArt() {
  return (
    <svg
      viewBox="0 0 330 700"
      className="absolute inset-0 w-full h-full"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#0F1729" />
          <stop offset="1" stopColor="#0B1220" />
        </linearGradient>
        <linearGradient id="pesoGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#4FBFA8" />
          <stop offset="1" stopColor="#2E8A78" />
        </linearGradient>
        <linearGradient id="aguaGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#3DB5C6" />
          <stop offset="1" stopColor="#287E8B" />
        </linearGradient>
        <linearGradient id="doseGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#4A90D9" />
          <stop offset="1" stopColor="#2B6CB0" />
        </linearGradient>
        <linearGradient id="refGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#E27D3F" />
          <stop offset="1" stopColor="#B35F28" />
        </linearGradient>
      </defs>

      {/* Fundo */}
      <rect width="330" height="700" fill="url(#bg)" />

      {/* Status bar simulada */}
      <g opacity="0.4">
        <rect x="30" y="26" width="30" height="6" rx="3" fill="#fff" />
        <rect x="270" y="26" width="30" height="6" rx="3" fill="#fff" />
      </g>

      {/* Header */}
      <g transform="translate(24, 60)">
        <text x="0" y="14" fill="#6B7893" fontSize="10" letterSpacing="2">
          SEGUNDA · 20 JUL
        </text>
        <text
          x="0"
          y="38"
          fill="#F1F5FB"
          fontSize="22"
          fontFamily="Georgia, serif"
        >
          Bom dia, Ana
        </text>
      </g>

      {/* Chip streak */}
      <g transform="translate(220, 68)">
        <rect
          width="86"
          height="26"
          rx="13"
          fill="#E9A03C"
          fillOpacity="0.18"
          stroke="#E9A03C"
          strokeOpacity="0.5"
        />
        <text
          x="43"
          y="17"
          fill="#E9A03C"
          fontSize="11"
          fontWeight="700"
          textAnchor="middle"
        >
          🔥 12 dias
        </text>
      </g>

      {/* Card grande — Peso */}
      <g transform="translate(24, 130)">
        <rect
          width="282"
          height="130"
          rx="22"
          fill="#131C2E"
          stroke="rgba(79,191,168,0.25)"
        />
        <circle cx="30" cy="30" r="16" fill="url(#pesoGrad)" opacity="0.9" />
        <text x="30" y="34" fill="#fff" fontSize="16" textAnchor="middle">
          ⚖
        </text>
        <text x="56" y="26" fill="#6B7893" fontSize="10" letterSpacing="2">
          PESO
        </text>
        <text
          x="56"
          y="46"
          fill="#F1F5FB"
          fontSize="14"
          fontWeight="600"
        >
          Hoje · 82,4 kg
        </text>

        {/* Delta */}
        <g transform="translate(200, 20)">
          <rect
            width="62"
            height="24"
            rx="12"
            fill="#4FBFA8"
            fillOpacity="0.18"
          />
          <text
            x="31"
            y="16"
            fill="#4FBFA8"
            fontSize="11"
            fontWeight="700"
            textAnchor="middle"
          >
            −0,3 kg
          </text>
        </g>

        {/* Mini gráfico — linha animada desenhando */}
        <g transform="translate(20, 68)">
          {/* Grid sutil */}
          <line
            x1="0"
            y1="45"
            x2="242"
            y2="45"
            stroke="#22304D"
            strokeDasharray="2 3"
          />
          {/* Área */}
          <path
            d="M0,20 L30,25 L60,18 L90,28 L120,32 L150,38 L180,42 L210,48 L242,52 L242,55 L0,55 Z"
            fill="url(#pesoGrad)"
            fillOpacity="0.12"
          />
          {/* Linha desenhando */}
          <path
            d="M0,20 L30,25 L60,18 L90,28 L120,32 L150,38 L180,42 L210,48 L242,52"
            fill="none"
            stroke="url(#pesoGrad)"
            strokeWidth="2.4"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeDasharray="290"
            strokeDashoffset="290"
            className="animate-hero-draw"
          />
          {/* Ponto "hoje" pulsando */}
          <circle
            cx="242"
            cy="52"
            r="4"
            fill="#4FBFA8"
            className="animate-pulseSoft"
          />
          <circle cx="242" cy="52" r="8" fill="#4FBFA8" fillOpacity="0.2" />
        </g>
      </g>

      {/* Row de 2 cards — Água + Dose */}
      <g transform="translate(24, 280)">
        {/* Água */}
        <g>
          <rect
            width="135"
            height="110"
            rx="20"
            fill="#131C2E"
            stroke="rgba(61,181,198,0.22)"
          />
          <text x="16" y="24" fill="#6B7893" fontSize="9" letterSpacing="1.8">
            ÁGUA
          </text>
          {/* Ring progresso */}
          <g transform="translate(67, 60)">
            <circle
              r="26"
              fill="none"
              stroke="#22304D"
              strokeWidth="5"
            />
            <circle
              r="26"
              fill="none"
              stroke="url(#aguaGrad)"
              strokeWidth="5"
              strokeLinecap="round"
              strokeDasharray="163"
              transform="rotate(-90)"
              className="animate-hero-waterRing"
            />
            <text
              y="4"
              fill="#F1F5FB"
              fontSize="14"
              fontWeight="700"
              textAnchor="middle"
            >
              78%
            </text>
          </g>
          <text
            x="67"
            y="102"
            fill="#9AA6B8"
            fontSize="9"
            textAnchor="middle"
          >
            1,8 / 2,3 L
          </text>
        </g>

        {/* Dose */}
        <g transform="translate(147, 0)">
          <rect
            width="135"
            height="110"
            rx="20"
            fill="#131C2E"
            stroke="rgba(74,144,217,0.22)"
          />
          <text x="16" y="24" fill="#6B7893" fontSize="9" letterSpacing="1.8">
            PRÓXIMA DOSE
          </text>
          <text
            x="16"
            y="52"
            fill="#F1F5FB"
            fontSize="22"
            fontFamily="Georgia, serif"
          >
            Quinta
          </text>
          <text x="16" y="72" fill="#4A90D9" fontSize="14" fontWeight="700">
            20:00
          </text>
          <text x="16" y="94" fill="#9AA6B8" fontSize="9">
            Ozempic · 1 mg
          </text>
          {/* Ícone caneta */}
          <g transform="translate(102, 46)" opacity="0.85">
            <rect
              x="0"
              y="0"
              width="18"
              height="42"
              rx="5"
              fill="url(#doseGrad)"
            />
            <rect x="4" y="30" width="10" height="6" fill="#E9A03C" />
            <polygon points="9,42 6,50 12,50" fill="#E1EAF5" />
          </g>
        </g>
      </g>

      {/* Row — Refeição + Sintomas cards */}
      <g transform="translate(24, 410)">
        <g>
          <rect
            width="135"
            height="86"
            rx="20"
            fill="#131C2E"
            stroke="rgba(226,125,63,0.22)"
          />
          <text x="16" y="24" fill="#6B7893" fontSize="9" letterSpacing="1.8">
            REFEIÇÕES
          </text>
          <text x="16" y="52" fill="#F1F5FB" fontSize="20" fontWeight="700">
            3 / 4
          </text>
          <text x="16" y="72" fill="#9AA6B8" fontSize="9">
            Proteína 68 g
          </text>
          <circle cx="112" cy="45" r="16" fill="url(#refGrad)" opacity="0.9" />
          <text x="112" y="50" fill="#fff" fontSize="14" textAnchor="middle">
            🍽
          </text>
        </g>

        <g transform="translate(147, 0)">
          <rect
            width="135"
            height="86"
            rx="20"
            fill="#131C2E"
            stroke="rgba(231,111,81,0.22)"
          />
          <text x="16" y="24" fill="#6B7893" fontSize="9" letterSpacing="1.8">
            SINTOMAS
          </text>
          <text x="16" y="52" fill="#F1F5FB" fontSize="20" fontWeight="700">
            2
          </text>
          <text x="16" y="72" fill="#9AA6B8" fontSize="9">
            Leves — 3 dias
          </text>
          {/* Chip intensidade */}
          <g transform="translate(94, 34)">
            <rect
              width="30"
              height="20"
              rx="10"
              fill="#4FBFA8"
              fillOpacity="0.2"
            />
            <text
              x="15"
              y="14"
              fill="#4FBFA8"
              fontSize="9"
              fontWeight="700"
              textAnchor="middle"
            >
              OK
            </text>
          </g>
        </g>
      </g>

      {/* Tab bar */}
      <g transform="translate(24, 620)">
        <rect
          width="282"
          height="58"
          rx="20"
          fill="#131C2E"
          stroke="rgba(255,255,255,0.06)"
        />
        {['◈', '＋', '◐', '◑'].map((g, i) => (
          <g key={i} transform={`translate(${28 + i * 74}, 15)`}>
            <circle
              r="14"
              cx="14"
              cy="14"
              fill={i === 0 ? '#4A90D9' : 'transparent'}
              opacity={i === 0 ? 0.2 : 1}
            />
            <text
              x="14"
              y="19"
              fill={i === 0 ? '#4A90D9' : '#6B7893'}
              fontSize="14"
              textAnchor="middle"
            >
              {g}
            </text>
          </g>
        ))}
      </g>
    </svg>
  );
}
