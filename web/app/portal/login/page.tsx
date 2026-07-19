'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { ApiError, login } from '@/lib/api';

export default function PortalLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);

  async function submeter(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setErro(null);
    setEnviando(true);
    try {
      const resposta = await login(email, senha);
      if (resposta.usuario.role !== 'profissional') {
        setErro(
          'Este acesso é exclusivo de profissionais verificados. Pacientes usam o app pelo celular.'
        );
        return;
      }
      router.push('/portal/pacientes');
    } catch (err) {
      if (err instanceof ApiError) {
        setErro(err.message);
      } else {
        setErro('Não foi possível conectar. Tente novamente.');
      }
    } finally {
      setEnviando(false);
    }
  }

  return (
    <section className="max-w-md mx-auto px-5 py-24">
      <div className="rounded-3xl border border-white/[0.08] bg-recorpo-surface/60 backdrop-blur-md p-8 md:p-10">
        <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-3">
          Portal do profissional
        </p>
        <h1 className="font-serif text-3xl md:text-4xl text-recorpo-text mb-2">
          Entrar
        </h1>
        <p className="text-recorpo-dim text-sm mb-8">
          Somente profissionais com registro CRM ou CRN verificado. O acesso
          aos pacientes exige convite feito pelo próprio paciente no app.
        </p>

        <form onSubmit={submeter} className="space-y-4">
          <label className="block">
            <span className="block text-xs font-semibold tracking-widest uppercase text-recorpo-dim mb-2">
              E-mail
            </span>
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-recorpo-bg/60 border border-white/[0.08] text-recorpo-text focus:outline-none focus:border-brand-primaryLight transition-colors"
              placeholder="seu@email.com"
            />
          </label>

          <label className="block">
            <span className="block text-xs font-semibold tracking-widest uppercase text-recorpo-dim mb-2">
              Senha
            </span>
            <input
              type="password"
              required
              autoComplete="current-password"
              value={senha}
              onChange={(e) => setSenha(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-recorpo-bg/60 border border-white/[0.08] text-recorpo-text focus:outline-none focus:border-brand-primaryLight transition-colors"
              placeholder="••••••••"
            />
          </label>

          {erro && (
            <div className="text-sm text-red-300 bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3">
              {erro}
            </div>
          )}

          <button
            type="submit"
            disabled={enviando}
            className="w-full font-semibold px-6 py-3.5 rounded-full bg-primary-gradient text-white shadow-glow hover:brightness-110 disabled:opacity-60 disabled:cursor-not-allowed transition-all"
          >
            {enviando ? 'Entrando…' : 'Entrar'}
          </button>
        </form>

        <p className="mt-6 text-xs text-recorpo-muted text-center">
          Todo acesso ao portal é registrado em auditoria (LGPD art. 37).
        </p>
      </div>
    </section>
  );
}
