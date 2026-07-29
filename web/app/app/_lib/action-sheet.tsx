'use client';

import { ReactNode, useEffect } from 'react';

/**
 * Sheet modal (drawer-from-bottom no mobile, dialog centrado no
 * desktop). Fecha por ESC ou clique no backdrop. Bloqueia scroll do
 * body enquanto aberto.
 *
 * Sem lib externa — Radix/dialog primitives seriam bacana mas não
 * queremos aumentar bundle só por isso.
 */
export function ActionSheet({
  aberto,
  titulo,
  onFechar,
  children,
}: {
  aberto: boolean;
  titulo: string;
  onFechar: () => void;
  children: ReactNode;
}) {
  useEffect(() => {
    if (!aberto) return;
    const original = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onFechar();
    }
    window.addEventListener('keydown', onKey);
    return () => {
      document.body.style.overflow = original;
      window.removeEventListener('keydown', onKey);
    };
  }, [aberto, onFechar]);

  if (!aberto) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-labelledby="sheet-titulo"
    >
      {/* Backdrop */}
      <button
        type="button"
        aria-label="Fechar"
        onClick={onFechar}
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
      />
      {/* Content */}
      <div className="relative w-full max-w-md rounded-t-2xl border border-recorpo-border bg-recorpo-surface p-6 shadow-glow sm:rounded-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2
            id="sheet-titulo"
            className="text-lg font-semibold text-recorpo-text"
          >
            {titulo}
          </h2>
          <button
            onClick={onFechar}
            className="rounded-md px-2 py-1 text-recorpo-dim hover:text-recorpo-text"
            aria-label="Fechar"
          >
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
