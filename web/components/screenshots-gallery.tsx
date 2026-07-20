'use client';

import { useState } from 'react';

const shots = [
  {
    file: '/screenshots/screenshot-1-boas-vindas.svg',
    title: 'Boas-vindas',
    caption: 'Onboarding em 3 telas — menos de 1 minuto até o primeiro registro.',
  },
  {
    file: '/screenshots/screenshot-2-dashboard.svg',
    title: 'Dashboard',
    caption: 'Quatro eixos numa tela — refeição, água, peso e sintomas em vista única.',
  },
  {
    file: '/screenshots/screenshot-3-lembrete-dose.svg',
    title: 'Lembrete da dose',
    caption: 'Notificação véspera + no dia. Escolhe o dia da semana e o horário.',
  },
  {
    file: '/screenshots/screenshot-4-sintomas.svg',
    title: 'Sintomas',
    caption: '15 sintomas curados de bulas Anvisa, registrados com intensidade.',
  },
  {
    file: '/screenshots/screenshot-5-pdf-medico.svg',
    title: 'PDF médico',
    caption: 'Um clique gera relatório completo em PDF para levar à consulta.',
  },
];

export default function ScreenshotsGallery() {
  const [active, setActive] = useState(1);

  return (
    <div className="relative">
      {/* Carrossel — desktop mostra 5, mobile scroll horizontal */}
      <div className="relative overflow-x-auto md:overflow-visible -mx-5 px-5 pb-6 md:pb-0 snap-x snap-mandatory md:snap-none">
        <div className="flex md:grid md:grid-cols-5 gap-4 md:gap-5 min-w-max md:min-w-0">
          {shots.map((s, i) => (
            <button
              key={s.file}
              type="button"
              onClick={() => setActive(i)}
              className={`snap-center shrink-0 md:shrink relative rounded-[28px] overflow-hidden border transition-all duration-500 group ${
                active === i
                  ? 'border-brand-primaryLight shadow-glow scale-[1.02] md:scale-[1.05] -translate-y-1'
                  : 'border-white/[0.08] hover:border-white/20 opacity-70 hover:opacity-100'
              }`}
              aria-label={`Ver screenshot ${i + 1}: ${s.title}`}
            >
              <div className="w-[210px] md:w-full aspect-[9/16] bg-recorpo-surface/60 relative">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={s.file}
                  alt={s.title}
                  className="w-full h-full object-cover"
                  loading={i < 2 ? 'eager' : 'lazy'}
                />
                {/* overlay gradiente sutil no rodapé pra ler o label */}
                <div className="absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-black/70 via-black/30 to-transparent pointer-events-none" />
                <div className="absolute inset-x-0 bottom-3 flex flex-col items-center">
                  <span className="text-[10px] tracking-[0.24em] uppercase text-brand-primaryLight font-semibold">
                    {String(i + 1).padStart(2, '0')}
                  </span>
                  <span className="text-white text-sm font-semibold">
                    {s.title}
                  </span>
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Caption do ativo */}
      <div className="mt-8 min-h-[3.5rem] text-center max-w-xl mx-auto">
        <p className="text-recorpo-dim text-lg leading-relaxed animate-rise" key={active}>
          {shots[active].caption}
        </p>
      </div>

      {/* Indicadores (dots) mobile */}
      <div className="mt-4 flex justify-center gap-1.5 md:hidden">
        {shots.map((_, i) => (
          <button
            key={i}
            type="button"
            onClick={() => setActive(i)}
            aria-label={`Ir para screenshot ${i + 1}`}
            className={`h-1.5 rounded-full transition-all ${
              active === i ? 'w-6 bg-brand-primaryLight' : 'w-1.5 bg-white/20'
            }`}
          />
        ))}
      </div>
    </div>
  );
}
