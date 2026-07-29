'use client';

import { useAuth } from './_lib/auth-provider';

export default function AppDashboardPage() {
  const { estado, logout } = useAuth();

  if (estado.status !== 'autenticado') {
    return (
      <main className="grid min-h-dvh place-items-center">
        <div
          className="h-8 w-8 animate-spin rounded-full border-2 border-recorpo-border border-t-brand-primaryLight"
          role="status"
          aria-label="Carregando"
        />
      </main>
    );
  }

  const { usuario } = estado;

  return (
    <main className="min-h-dvh px-6 py-10">
      <div className="mx-auto max-w-3xl">
        <header className="mb-8 flex items-center justify-between">
          <div>
            <p className="text-xs font-medium uppercase tracking-wider text-recorpo-dim">
              Recorpo · Assistente GLP-1
            </p>
            <h1 className="mt-1 text-2xl font-semibold text-recorpo-text">
              Olá, {usuario.nome ?? usuario.email}
            </h1>
          </div>
          <button
            onClick={logout}
            className="rounded-lg border border-recorpo-border px-3 py-1.5 text-sm text-recorpo-dim hover:border-brand-primary hover:text-recorpo-text transition"
          >
            Sair
          </button>
        </header>

        <div className="rounded-2xl border border-recorpo-border bg-recorpo-surface p-8">
          <p className="text-recorpo-dim">
            Dashboard em construção — F1.3 vem a seguir.
          </p>
          <p className="mt-2 text-xs text-recorpo-muted">
            Autenticado como <code className="rounded bg-recorpo-bg px-1.5 py-0.5">{usuario.email}</code> · role={' '}
            <code className="rounded bg-recorpo-bg px-1.5 py-0.5">{usuario.role}</code>
          </p>
        </div>
      </div>
    </main>
  );
}
