import dynamic from 'next/dynamic';
import Nav from '@/components/nav';
import Footer from '@/components/footer';
import EixoCards from '@/components/eixo-cards';
import RevealOnScroll from '@/components/reveal-on-scroll';
import ScreenshotsGallery from '@/components/screenshots-gallery';

// R3F precisa ser client-side. WebGL pode travar em browsers headless
// (preview interno) — verificamos via env var para desabilitar o Canvas
// só no preview e manter o hero 3D em prod. Quando desabilitado, o
// módulo three/R3F nem entra no bundle.
const disableCanvas = process.env.NEXT_PUBLIC_DISABLE_3D === '1';
const Hero3D = disableCanvas
  ? null
  : dynamic(() => import('@/components/hero-3d'), {
      ssr: false,
      loading: () => <div className="w-full h-[420px] md:h-[500px]" />,
    });

export default function Home() {
  return (
    <>
      <Nav />

      {/* ===== HERO ===== */}
      <section className="relative pt-14 pb-24 overflow-hidden">
        <div className="mist" aria-hidden>
          <span />
          <span />
          <span />
        </div>

        <div className="relative max-w-6xl mx-auto px-5 grid md:grid-cols-2 gap-10 items-center">
          <div className="animate-rise">
            <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-5">
              Assistente de Caneta GLP-1
            </p>
            <h1 className="font-serif text-[clamp(44px,7vw,80px)] leading-[0.98] text-recorpo-text">
              O seu tratamento{' '}
              <span className="italic bg-primary-gradient bg-clip-text text-transparent">
                merece
              </span>{' '}
              acompanhamento próprio.
            </h1>
            <p className="mt-6 text-lg text-recorpo-dim max-w-lg leading-relaxed">
              Registre suas aplicações, veja sua evolução com clareza e leve um
              relatório médico completo para quem cuida de você. Sem promessas
              milagrosas — só ferramenta séria pra jornada real.
            </p>

            <div className="mt-8 flex flex-wrap gap-3">
              <a
                href="#baixar"
                className="inline-flex items-center gap-2 font-semibold px-6 py-3.5 rounded-full bg-primary-gradient text-white shadow-glow hover:shadow-glowSoft hover:-translate-y-0.5 transition-all"
              >
                Baixar grátis
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </a>
              <a
                href="#recursos"
                className="inline-flex items-center gap-2 font-semibold px-6 py-3.5 rounded-full border border-white/10 text-recorpo-text hover:border-brand-primaryLight hover:text-brand-primaryLight transition-colors"
              >
                Ver como funciona
              </a>
            </div>

            <div className="mt-10 grid grid-cols-3 gap-6 max-w-md">
              <Stat n="15" l="Sintomas curados de bulas Anvisa" />
              <Stat n="4" l="Eixos farmacológicos" />
              <Stat n="LGPD" l="+ padrão HIPAA" />
            </div>
          </div>

          {/* Coluna 3D — em preview headless, mostramos placeholder SVG */}
          <div className="relative">
            {Hero3D ? <Hero3D /> : <HeroFallback />}
          </div>
        </div>
      </section>

      {/* ===== SCREENSHOTS DO APP ===== */}
      <RevealOnScroll>
        <section id="app" className="relative max-w-6xl mx-auto px-5 py-24">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-3">
              Por dentro do app
            </p>
            <h2 className="font-serif text-4xl md:text-5xl text-recorpo-text">
              Sério e claro, do onboarding ao PDF do médico.
            </h2>
            <p className="mt-4 text-recorpo-dim">
              Cinco telas que resumem o dia-a-dia com o Recorpo. Toca em qualquer
              uma pra abrir em foco.
            </p>
          </div>

          <ScreenshotsGallery />
        </section>
      </RevealOnScroll>

      {/* ===== EIXOS ===== */}
      <RevealOnScroll>
        <section id="recursos" className="relative max-w-6xl mx-auto px-5 py-24">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-3">
              Como o Recorpo cuida
            </p>
            <h2 className="font-serif text-4xl md:text-5xl text-recorpo-text">
              Quatro eixos, uma visão inteira.
            </h2>
            <p className="mt-4 text-recorpo-dim">
              A gente organiza seu dia em quatro cuidados essenciais e
              transforma isso em evolução visível para você e para o seu médico.
            </p>
          </div>

          <EixoCards />
        </section>
      </RevealOnScroll>

      {/* ===== BAIXAR ===== */}
      <RevealOnScroll>
        <section id="baixar" className="relative max-w-4xl mx-auto px-5 py-24 text-center">
          <div className="relative rounded-3xl border border-white/[0.08] bg-recorpo-surface/60 backdrop-blur-md p-10 md:p-14 overflow-hidden">
            <div className="absolute -top-20 -right-16 w-72 h-72 rounded-full bg-brand-primary/25 blur-3xl" aria-hidden />
            <div className="absolute -bottom-24 -left-10 w-72 h-72 rounded-full bg-eixo-agua/20 blur-3xl" aria-hidden />

            <h2 className="relative font-serif text-4xl md:text-5xl text-recorpo-text">
              Baixe grátis. Continue sério.
            </h2>
            <p className="relative mt-4 text-recorpo-dim max-w-xl mx-auto">
              O app é gratuito para os cuidados essenciais. Recursos avançados
              (IA de refeição, PDF médico enriquecido, quota ilimitada) ficam no
              Premium, R$ 19,90/mês.
            </p>
            <div className="relative mt-8 flex flex-wrap justify-center gap-3">
              <a
                href="https://play.google.com/store/apps/details?id=com.recorpo.app"
                className="inline-flex items-center gap-2 font-semibold px-6 py-3.5 rounded-full bg-primary-gradient text-white shadow-glow hover:-translate-y-0.5 transition-transform"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3 20.5V3.5a1 1 0 011.5-.87l14 8.5a1 1 0 010 1.74l-14 8.5A1 1 0 013 20.5z" />
                </svg>
                Google Play
              </a>
              <a
                href="/suporte"
                className="inline-flex items-center gap-2 font-semibold px-6 py-3.5 rounded-full border border-white/10 text-recorpo-text hover:border-brand-primaryLight hover:text-brand-primaryLight transition-colors"
              >
                Falar com o time
              </a>
            </div>
            <p className="relative mt-6 text-xs text-recorpo-muted">
              iOS em breve · Assinatura pode ser cancelada a qualquer momento
            </p>
          </div>
        </section>
      </RevealOnScroll>

      <Footer />
    </>
  );
}

/** Placeholder ilustrativo para quando o Canvas 3D é desabilitado. */
function HeroFallback() {
  return (
    <div className="relative w-full h-[420px] md:h-[500px] flex items-center justify-center">
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none" aria-hidden>
        <div className="w-[380px] h-[380px] md:w-[520px] md:h-[520px] rounded-full bg-brand-primary/30 blur-[100px] animate-pulseSoft" />
      </div>
      <svg viewBox="0 0 220 480" className="relative h-[320px] md:h-[420px]" xmlns="http://www.w3.org/2000/svg" aria-hidden>
        <defs>
          <linearGradient id="body" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#1A2540" />
            <stop offset="1" stopColor="#0B1220" />
          </linearGradient>
          <linearGradient id="liquid" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#4A90D9" />
            <stop offset="1" stopColor="#2B6CB0" />
          </linearGradient>
          <linearGradient id="btn" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#F1C87C" />
            <stop offset="1" stopColor="#E9A03C" />
          </linearGradient>
        </defs>
        {/* Botão superior */}
        <ellipse cx="110" cy="34" rx="42" ry="30" fill="url(#btn)" />
        <rect x="70" y="52" width="80" height="14" rx="7" fill="#4A90D9" />
        {/* Corpo */}
        <rect x="72" y="72" width="76" height="180" rx="12" fill="url(#body)" />
        {/* Marcadores de dose */}
        <line x1="72" y1="120" x2="148" y2="120" stroke="#4A90D9" strokeWidth="1.5" />
        <line x1="72" y1="160" x2="148" y2="160" stroke="#4A90D9" strokeWidth="1.5" />
        <line x1="72" y1="200" x2="148" y2="200" stroke="#4A90D9" strokeWidth="1.5" />
        {/* Anel âmbar */}
        <rect x="70" y="252" width="80" height="18" rx="4" fill="#E9A03C" />
        {/* Cápsula com líquido */}
        <rect x="80" y="272" width="60" height="110" rx="6" fill="#4A90D9" opacity="0.35" />
        <rect x="94" y="284" width="32" height="90" rx="4" fill="url(#liquid)" />
        {/* Base */}
        <rect x="76" y="386" width="68" height="30" rx="6" fill="#0B1220" />
        {/* Agulha */}
        <polygon points="110,416 106,448 114,448" fill="#E1EAF5" />
      </svg>
    </div>
  );
}

function Stat({ n, l }: { n: string; l: string }) {
  return (
    <div>
      <div className="font-serif text-3xl text-brand-primaryLight leading-none">
        {n}
      </div>
      <div className="text-[11px] text-recorpo-muted mt-1.5 leading-tight">
        {l}
      </div>
    </div>
  );
}
