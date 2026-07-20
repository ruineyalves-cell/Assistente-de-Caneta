'use client';

import { useEffect, useRef, useState, useCallback } from 'react';

const shots = [
  {
    file: '/screenshots/screenshot-1-boas-vindas.svg',
    title: 'Boas-vindas',
    caption:
      'Onboarding em 3 telas — menos de 1 minuto até o primeiro registro.',
  },
  {
    file: '/screenshots/screenshot-2-dashboard.svg',
    title: 'Dashboard',
    caption:
      'Quatro eixos numa tela — refeição, água, peso e sintomas em vista única.',
  },
  {
    file: '/screenshots/screenshot-3-lembrete-dose.svg',
    title: 'Lembrete da dose',
    caption:
      'Notificação véspera + no dia. Escolhe o dia da semana e o horário.',
  },
  {
    file: '/screenshots/screenshot-4-sintomas.svg',
    title: 'Sintomas',
    caption:
      '15 sintomas curados de bulas Anvisa, registrados com intensidade.',
  },
  {
    file: '/screenshots/screenshot-5-pdf-medico.svg',
    title: 'PDF médico',
    caption: 'Um clique gera relatório completo em PDF para levar à consulta.',
  },
];

const AUTOPLAY_MS = 6000;

export default function ScreenshotsGallery() {
  const [active, setActive] = useState(0);
  const [paused, setPaused] = useState(false);
  const total = shots.length;

  const go = useCallback(
    (dir: 1 | -1) => setActive((i) => (i + dir + total) % total),
    [total],
  );

  // Autoplay — pausa quando hover ou quando aba fica em background
  useEffect(() => {
    if (paused) return;
    const id = setInterval(() => go(1), AUTOPLAY_MS);
    return () => clearInterval(id);
  }, [paused, go, active]);

  useEffect(() => {
    const onVis = () => setPaused(document.hidden);
    document.addEventListener('visibilitychange', onVis);
    return () => document.removeEventListener('visibilitychange', onVis);
  }, []);

  // Suporte a teclado (setas esquerda/direita)
  const rootRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = rootRef.current;
    if (!el) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight') go(1);
      if (e.key === 'ArrowLeft') go(-1);
    };
    el.addEventListener('keydown', onKey);
    return () => el.removeEventListener('keydown', onKey);
  }, [go]);

  return (
    <div
      ref={rootRef}
      tabIndex={0}
      className="relative outline-none"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={() => setPaused(false)}
      aria-roledescription="carousel"
      aria-label="Screenshots do app Recorpo"
    >
      {/* Palco: 3 imagens (anterior, atual, próxima) com destaque no meio */}
      <div className="relative h-[560px] sm:h-[640px] md:h-[720px] flex items-center justify-center overflow-hidden">
        {/* Halo por trás do card ativo */}
        <div
          aria-hidden
          className="absolute inset-0 flex items-center justify-center pointer-events-none"
        >
          <div className="w-[420px] h-[420px] rounded-full bg-brand-primary/20 blur-[110px] animate-pulseSoft" />
        </div>

        {shots.map((s, i) => {
          // posição relativa ao ativo (-2..2)
          let offset = i - active;
          if (offset > total / 2) offset -= total;
          if (offset < -total / 2) offset += total;

          // Só renderizamos os 5 slots visíveis para performance
          if (Math.abs(offset) > 2) return null;

          const isActive = offset === 0;

          // Translação em pixels + rotação sutil + escala
          const tx = offset * 200;
          const scale = isActive ? 1 : Math.abs(offset) === 1 ? 0.78 : 0.6;
          const rotateY = offset * -14;
          const zIndex = 10 - Math.abs(offset);
          const opacity = isActive
            ? 1
            : Math.abs(offset) === 1
              ? 0.55
              : 0.25;

          return (
            <button
              key={s.file}
              type="button"
              onClick={() => setActive(i)}
              tabIndex={isActive ? 0 : -1}
              aria-hidden={!isActive}
              aria-label={
                isActive
                  ? `Screenshot atual: ${s.title}`
                  : `Ir para: ${s.title}`
              }
              className="absolute top-1/2 left-1/2 transition-all duration-700 ease-out will-change-transform"
              style={{
                transform: `translate(-50%, -50%) translateX(${tx}px) rotateY(${rotateY}deg) scale(${scale})`,
                zIndex,
                opacity,
                filter: isActive ? 'none' : 'blur(1px)',
                cursor: isActive ? 'default' : 'pointer',
                perspective: 1200,
              }}
            >
              <div
                className={`relative w-[280px] sm:w-[320px] md:w-[360px] aspect-[9/19.5] rounded-[36px] overflow-hidden border transition-shadow ${
                  isActive
                    ? 'border-brand-primaryLight shadow-glow'
                    : 'border-white/[0.08] shadow-2xl shadow-black/60'
                }`}
              >
                {/* Molduras estilo aparelho: notch + bordas escuras */}
                <div className="absolute inset-0 bg-black" aria-hidden />
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={s.file}
                  alt={s.title}
                  className="relative w-full h-full object-cover"
                  loading={i < 2 ? 'eager' : 'lazy'}
                  draggable={false}
                />
                {/* Notch superior */}
                <div
                  aria-hidden
                  className="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-6 bg-black rounded-full opacity-90"
                />
                {/* Reflexo diagonal sutil */}
                <div
                  aria-hidden
                  className="absolute inset-0 pointer-events-none bg-gradient-to-tr from-transparent via-white/[0.04] to-transparent"
                />
              </div>
            </button>
          );
        })}

        {/* Seta esquerda — sempre visível, grande e óbvia */}
        <button
          type="button"
          onClick={() => go(-1)}
          aria-label="Screenshot anterior"
          className="absolute left-1 md:left-4 top-1/2 -translate-y-1/2 z-30 group"
        >
          <span className="flex items-center justify-center w-12 h-12 md:w-14 md:h-14 rounded-full bg-recorpo-surface/80 backdrop-blur-md border border-white/10 text-recorpo-text hover:bg-brand-primary hover:text-white hover:border-brand-primaryLight hover:scale-110 transition-all shadow-xl shadow-black/40">
            <svg
              width="22"
              height="22"
              viewBox="0 0 24 24"
              fill="none"
              className="group-hover:-translate-x-0.5 transition-transform"
            >
              <path
                d="M15 6l-6 6 6 6"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
        </button>

        {/* Seta direita */}
        <button
          type="button"
          onClick={() => go(1)}
          aria-label="Próximo screenshot"
          className="absolute right-1 md:right-4 top-1/2 -translate-y-1/2 z-30 group"
        >
          <span className="flex items-center justify-center w-12 h-12 md:w-14 md:h-14 rounded-full bg-recorpo-surface/80 backdrop-blur-md border border-white/10 text-recorpo-text hover:bg-brand-primary hover:text-white hover:border-brand-primaryLight hover:scale-110 transition-all shadow-xl shadow-black/40">
            <svg
              width="22"
              height="22"
              viewBox="0 0 24 24"
              fill="none"
              className="group-hover:translate-x-0.5 transition-transform"
            >
              <path
                d="M9 6l6 6-6 6"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
        </button>
      </div>

      {/* Caption + índice */}
      <div className="mt-8 max-w-xl mx-auto text-center min-h-[5rem]">
        <p
          key={active}
          className="text-[11px] tracking-[0.28em] uppercase text-brand-primaryLight font-semibold mb-2 animate-rise"
        >
          {String(active + 1).padStart(2, '0')} · {shots[active].title}
        </p>
        <p
          key={`c${active}`}
          className="text-recorpo-dim text-lg leading-relaxed animate-rise"
        >
          {shots[active].caption}
        </p>
      </div>

      {/* Indicadores (dots + barra de progresso do autoplay) */}
      <div className="mt-6 flex flex-col items-center gap-3">
        <div className="flex gap-2">
          {shots.map((_, i) => (
            <button
              key={i}
              type="button"
              onClick={() => setActive(i)}
              aria-label={`Ir para screenshot ${i + 1}`}
              className={`h-1.5 rounded-full transition-all ${
                active === i
                  ? 'w-8 bg-brand-primaryLight'
                  : 'w-1.5 bg-white/20 hover:bg-white/40'
              }`}
            />
          ))}
        </div>
        <span className="text-[10px] tracking-widest uppercase text-recorpo-muted">
          {paused
            ? 'Autoplay pausado · use as setas'
            : 'Autoplay · passa em 6s'}
        </span>
      </div>
    </div>
  );
}
