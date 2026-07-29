'use client';

/**
 * Primitivos visuais reutilizáveis do portal do paciente. Espelham o
 * design system do app Flutter (dark-first, azul-clínico, eixos por
 * cor). Ficam aqui pra não repetir Tailwind grande em cada tela.
 */

import { ReactNode } from 'react';

export function Card({
  children,
  className = '',
  as: Tag = 'div',
  eixo,
}: {
  children: ReactNode;
  className?: string;
  as?: 'div' | 'button' | 'a';
  eixo?: 'refeicao' | 'agua' | 'peso' | 'sintomas' | 'streak' | 'movimento';
}) {
  const eixoBorder: Record<NonNullable<typeof eixo>, string> = {
    refeicao: 'border-l-eixo-refeicao',
    agua: 'border-l-eixo-agua',
    peso: 'border-l-eixo-peso',
    sintomas: 'border-l-eixo-sintomas',
    streak: 'border-l-eixo-streak',
    movimento: 'border-l-eixo-movimento',
  };
  const eixoClass = eixo ? `border-l-4 ${eixoBorder[eixo]}` : '';
  return (
    <Tag
      className={`rounded-2xl border border-recorpo-border bg-recorpo-surface p-5 ${eixoClass} ${className}`}
    >
      {children}
    </Tag>
  );
}

export function Skeleton({ className = '' }: { className?: string }) {
  return (
    <div
      className={`animate-pulse rounded bg-recorpo-surfaceHi ${className}`}
      aria-hidden
    />
  );
}

export function Label({ children }: { children: ReactNode }) {
  return (
    <span className="block text-[10px] font-semibold uppercase tracking-[0.12em] text-recorpo-dim">
      {children}
    </span>
  );
}

export function Kpi({
  valor,
  unidade,
  hint,
}: {
  valor: ReactNode;
  unidade?: string;
  hint?: string;
}) {
  return (
    <div>
      <div className="flex items-baseline gap-1.5">
        <span className="text-3xl font-semibold tabular-nums text-recorpo-text">
          {valor}
        </span>
        {unidade && (
          <span className="text-sm text-recorpo-dim">{unidade}</span>
        )}
      </div>
      {hint && <span className="mt-0.5 block text-xs text-recorpo-dim">{hint}</span>}
    </div>
  );
}

export function EmptyState({
  icone,
  titulo,
  descricao,
}: {
  icone: string;
  titulo: string;
  descricao?: string;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 py-8 text-center">
      <span className="text-4xl" aria-hidden>
        {icone}
      </span>
      <p className="text-sm font-medium text-recorpo-text">{titulo}</p>
      {descricao && <p className="max-w-xs text-xs text-recorpo-dim">{descricao}</p>}
    </div>
  );
}

export function ErroBox({
  mensagem,
  onTentar,
}: {
  mensagem: string;
  onTentar?: () => void;
}) {
  return (
    <div className="rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/10 p-4 text-sm text-eixo-sintomas">
      <p className="mb-2">{mensagem}</p>
      {onTentar && (
        <button
          onClick={onTentar}
          className="rounded border border-eixo-sintomas/60 px-2 py-1 text-xs hover:bg-eixo-sintomas/20"
        >
          Tentar de novo
        </button>
      )}
    </div>
  );
}
