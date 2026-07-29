'use client';

import Link from 'next/link';
import { useState } from 'react';
import { useAuth } from '../_lib/auth-provider';

export default function AppLoginPage() {
  const { login, estado } = useAuth();
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [mostrarSenha, setMostrarSenha] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);

  async function submeter(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (enviando) return;
    setErro(null);
    setEnviando(true);
    const r = await login(email.trim(), senha);
    if (!r.ok) setErro(r.erro ?? 'Falha no login');
    setEnviando(false);
    // redirect é feito pelo AuthProvider quando estado vira "autenticado"
  }

  // Se ainda estamos verificando sessão (refresh no boot), evita flash
  // do form. Layout do provider já cuida do redirect pós-login.
  if (estado.status === 'carregando') {
    return <SplashCarregando />;
  }

  return (
    <main className="min-h-dvh flex items-center justify-center px-6 py-12">
      <div className="w-full max-w-md">
        <Link
          href="/"
          className="mb-8 inline-flex items-center gap-2 text-sm text-recorpo-dim hover:text-recorpo-text transition"
        >
          <span aria-hidden>←</span> Voltar ao site
        </Link>

        <div className="rounded-2xl border border-recorpo-border bg-recorpo-surface p-8 shadow-glowSoft">
          <div className="mb-6">
            <div className="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-full bg-brand-primary/15">
              <span className="text-2xl" role="img" aria-label="Recorpo">
                💠
              </span>
            </div>
            <h1 className="text-2xl font-semibold tracking-tight text-recorpo-text">
              Entrar no Recorpo
            </h1>
            <p className="mt-1 text-sm text-recorpo-dim">
              Acompanhe seu tratamento GLP-1 pelo navegador — funciona em
              qualquer aparelho.
            </p>
          </div>

          <form onSubmit={submeter} className="space-y-4" noValidate>
            <label className="block">
              <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
                Email
              </span>
              <input
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none transition focus:border-brand-primaryLight focus:ring-2 focus:ring-brand-primaryLight/30"
                placeholder="seu@email.com"
              />
            </label>

            <label className="block">
              <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
                Senha
              </span>
              <div className="relative">
                <input
                  type={mostrarSenha ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                  className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 pr-12 text-recorpo-text outline-none transition focus:border-brand-primaryLight focus:ring-2 focus:ring-brand-primaryLight/30"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setMostrarSenha((v) => !v)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md px-2 py-1 text-xs text-recorpo-dim hover:text-recorpo-text"
                  aria-label={mostrarSenha ? 'Ocultar senha' : 'Mostrar senha'}
                >
                  {mostrarSenha ? 'Ocultar' : 'Mostrar'}
                </button>
              </div>
            </label>

            {erro && (
              <div
                role="alert"
                className="rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/10 px-3 py-2 text-sm text-eixo-sintomas"
              >
                {erro}
              </div>
            )}

            <button
              type="submit"
              disabled={enviando || !email || !senha}
              className="w-full rounded-lg bg-brand-primary py-3 font-medium text-white transition hover:bg-brand-primaryDark disabled:cursor-not-allowed disabled:opacity-50"
            >
              {enviando ? 'Entrando…' : 'Entrar'}
            </button>

            <div className="pt-2 text-center text-sm text-recorpo-dim">
              Não tem conta?{' '}
              <Link
                href="/app/registro"
                className="text-brand-primaryLight hover:underline"
              >
                Criar uma
              </Link>
            </div>
          </form>
        </div>

        <p className="mt-6 text-center text-xs text-recorpo-muted">
          Sua senha é enviada só pro servidor Recorpo, nunca a terceiros.
          Sessão protegida por token httpOnly.
        </p>
      </div>
    </main>
  );
}

function SplashCarregando() {
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
