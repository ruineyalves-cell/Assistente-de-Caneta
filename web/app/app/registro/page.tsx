'use client';

import Link from 'next/link';
import { useState } from 'react';
import { useAuth } from '../_lib/auth-provider';

// Regex igual ao backend/models/userModel.js pra evitar erro de validação
// no submit (feedback imediato ao user).
const SENHA_MIN = 8;

export default function AppRegistroPage() {
  const { registrar, estado } = useAuth();
  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [dataNascimento, setDataNascimento] = useState('');
  const [aceito, setAceito] = useState(false);
  const [mostrarSenha, setMostrarSenha] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);

  const senhaValida = senha.length >= SENHA_MIN;
  const formularioValido =
    nome.trim().length >= 2 &&
    /.+@.+\..+/.test(email) &&
    senhaValida &&
    dataNascimento.length === 10 &&
    aceito;

  async function submeter(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (enviando || !formularioValido) return;
    setErro(null);
    setEnviando(true);
    const r = await registrar({
      nome: nome.trim(),
      email: email.trim(),
      senha,
      dataNascimento,
    });
    if (!r.ok) setErro(r.erro ?? 'Falha no cadastro');
    setEnviando(false);
  }

  if (estado.status === 'carregando') {
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

  return (
    <main className="min-h-dvh flex items-center justify-center px-6 py-12">
      <div className="w-full max-w-md">
        <Link
          href="/app/login"
          className="mb-6 inline-flex items-center gap-2 text-sm text-recorpo-dim hover:text-recorpo-text transition"
        >
          <span aria-hidden>←</span> Já tenho conta
        </Link>

        <div className="rounded-2xl border border-recorpo-border bg-recorpo-surface p-8 shadow-glowSoft">
          <h1 className="text-2xl font-semibold tracking-tight text-recorpo-text">
            Criar conta
          </h1>
          <p className="mt-1 text-sm text-recorpo-dim">
            Grátis. Você pode assinar Premium depois pra desbloquear IA
            de refeição, bula e rótulo.
          </p>

          <form onSubmit={submeter} className="mt-6 space-y-4" noValidate>
            <Campo
              label="Nome"
              value={nome}
              onChange={setNome}
              autoComplete="name"
              placeholder="Seu nome"
            />
            <Campo
              label="Email"
              type="email"
              value={email}
              onChange={setEmail}
              autoComplete="email"
              placeholder="seu@email.com"
            />
            <Campo
              label="Data de nascimento"
              type="date"
              value={dataNascimento}
              onChange={setDataNascimento}
              autoComplete="bday"
              placeholder=""
            />

            <label className="block">
              <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
                Senha
              </span>
              <div className="relative">
                <input
                  type={mostrarSenha ? 'text' : 'password'}
                  autoComplete="new-password"
                  required
                  minLength={SENHA_MIN}
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                  className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 pr-12 text-recorpo-text outline-none transition focus:border-brand-primaryLight focus:ring-2 focus:ring-brand-primaryLight/30"
                  placeholder={`Mínimo ${SENHA_MIN} caracteres`}
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
              {senha.length > 0 && !senhaValida && (
                <span className="mt-1 block text-xs text-eixo-sintomas">
                  Faltam {SENHA_MIN - senha.length} caractere(s).
                </span>
              )}
            </label>

            <label className="flex items-start gap-3 text-sm text-recorpo-dim">
              <input
                type="checkbox"
                checked={aceito}
                onChange={(e) => setAceito(e.target.checked)}
                className="mt-0.5 h-4 w-4 rounded border-recorpo-border bg-recorpo-bg accent-brand-primary"
              />
              <span>
                Li e concordo com os{' '}
                <Link
                  href="/termos"
                  target="_blank"
                  className="text-brand-primaryLight hover:underline"
                >
                  Termos
                </Link>{' '}
                e a{' '}
                <Link
                  href="/privacidade"
                  target="_blank"
                  className="text-brand-primaryLight hover:underline"
                >
                  Política de Privacidade
                </Link>{' '}
                (LGPD).
              </span>
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
              disabled={enviando || !formularioValido}
              className="w-full rounded-lg bg-brand-primary py-3 font-medium text-white transition hover:bg-brand-primaryDark disabled:cursor-not-allowed disabled:opacity-50"
            >
              {enviando ? 'Criando conta…' : 'Criar conta'}
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}

function Campo({
  label,
  value,
  onChange,
  type = 'text',
  autoComplete,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  autoComplete?: string;
  placeholder?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
        {label}
      </span>
      <input
        type={type}
        autoComplete={autoComplete}
        required
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none transition focus:border-brand-primaryLight focus:ring-2 focus:ring-brand-primaryLight/30"
      />
    </label>
  );
}
