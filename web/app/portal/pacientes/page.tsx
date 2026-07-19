'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import {
  ApiError,
  clearToken,
  isAutenticado,
  listarPacientes,
  type PacienteResumo,
} from '@/lib/api';

export default function PacientesListaPage() {
  const router = useRouter();
  const [pacientes, setPacientes] = useState<PacienteResumo[] | null>(null);
  const [erro, setErro] = useState<string | null>(null);

  useEffect(() => {
    if (!isAutenticado()) {
      router.replace('/portal/login');
      return;
    }
    listarPacientes()
      .then((r) => setPacientes(r.pacientes))
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) {
          clearToken();
          router.replace('/portal/login');
          return;
        }
        setErro(err instanceof Error ? err.message : 'Erro inesperado.');
      });
  }, [router]);

  return (
    <section className="max-w-4xl mx-auto px-5 py-16">
      <div className="flex flex-wrap items-end justify-between gap-4 mb-10">
        <div>
          <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-2">
            Portal do profissional
          </p>
          <h1 className="font-serif text-4xl text-recorpo-text">
            Seus pacientes vinculados
          </h1>
        </div>
        <button
          onClick={() => {
            clearToken();
            router.push('/portal/login');
          }}
          className="text-sm text-recorpo-dim hover:text-recorpo-text transition-colors"
        >
          Sair
        </button>
      </div>

      {erro && (
        <div className="text-sm text-red-300 bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 mb-6">
          {erro}
        </div>
      )}

      {pacientes === null && !erro && (
        <div className="text-recorpo-dim animate-pulseSoft">Carregando…</div>
      )}

      {pacientes && pacientes.length === 0 && (
        <div className="rounded-2xl border border-white/[0.08] bg-recorpo-surface/60 p-8 text-center">
          <p className="text-recorpo-dim">
            Nenhum paciente ainda. O convite parte do próprio paciente pelo
            app — quando ele autorizar você, aparece por aqui.
          </p>
        </div>
      )}

      {pacientes && pacientes.length > 0 && (
        <ul className="space-y-3">
          {pacientes.map((p) => (
            <li key={p.id}>
              <Link
                href={`/portal/paciente/${p.id}`}
                className="flex items-center justify-between gap-4 rounded-2xl border border-white/[0.08] bg-recorpo-surface/60 hover:border-brand-primaryLight/60 hover:bg-recorpo-surfaceHi/70 transition-all p-5 group"
              >
                <div className="flex items-center gap-4 min-w-0">
                  <div className="w-11 h-11 rounded-full bg-primary-gradient flex items-center justify-center text-white font-serif text-lg shrink-0">
                    {(p.nome ?? p.email).slice(0, 1).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <div className="font-medium text-recorpo-text truncate">
                      {p.nome ?? p.email}
                    </div>
                    <div className="text-xs text-recorpo-muted truncate">
                      {p.email}
                    </div>
                  </div>
                </div>
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  className="text-recorpo-dim group-hover:text-brand-primaryLight transition-colors shrink-0"
                >
                  <path
                    d="M9 6l6 6-6 6"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
