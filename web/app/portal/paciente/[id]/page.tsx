'use client';

import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import {
  ApiError,
  baixarRelatorioPdf,
  clearToken,
  isAutenticado,
  obterPaciente,
  type PacienteDetalhe,
} from '@/lib/api';

export default function PacienteDetalhePage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const id = params.id;

  const [dados, setDados] = useState<PacienteDetalhe | null>(null);
  const [erro, setErro] = useState<string | null>(null);
  const [baixando, setBaixando] = useState(false);

  useEffect(() => {
    if (!isAutenticado()) {
      router.replace('/portal/login');
      return;
    }
    if (!id) return;
    obterPaciente(id)
      .then((d) => setDados(d))
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) {
          clearToken();
          router.replace('/portal/login');
          return;
        }
        setErro(err instanceof Error ? err.message : 'Erro inesperado.');
      });
  }, [id, router]);

  async function handleBaixarPdf() {
    if (!id) return;
    setBaixando(true);
    try {
      const blob = await baixarRelatorioPdf(id);
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `relatorio-${id.slice(0, 8)}.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      setErro(err instanceof Error ? err.message : 'Falha ao baixar.');
    } finally {
      setBaixando(false);
    }
  }

  if (erro) {
    return (
      <section className="max-w-3xl mx-auto px-5 py-16">
        <Link
          href="/portal/pacientes"
          className="text-sm text-recorpo-dim hover:text-recorpo-text mb-6 inline-block"
        >
          ← Voltar aos pacientes
        </Link>
        <div className="text-sm text-red-300 bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3">
          {erro}
        </div>
      </section>
    );
  }

  if (!dados) {
    return (
      <section className="max-w-3xl mx-auto px-5 py-16">
        <div className="text-recorpo-dim animate-pulseSoft">Carregando…</div>
      </section>
    );
  }

  const perfil = dados.perfil;
  const pesoAtual = dados.logs.find((l) => l.pesoKg != null)?.pesoKg ?? null;

  return (
    <section className="max-w-4xl mx-auto px-5 py-16">
      <Link
        href="/portal/pacientes"
        className="text-sm text-recorpo-dim hover:text-recorpo-text mb-6 inline-block"
      >
        ← Voltar aos pacientes
      </Link>

      <div className="flex flex-wrap items-start justify-between gap-4 mb-10">
        <div>
          <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-2">
            Prontuário read-only · auditado
          </p>
          <h1 className="font-serif text-4xl text-recorpo-text">
            {perfil?.medicacao?.nome ?? 'Paciente'}
          </h1>
          <p className="text-recorpo-dim mt-1">
            Streak atual: <span className="text-recorpo-text">{dados.streak}</span>{' '}
            dias
          </p>
        </div>
        <button
          onClick={handleBaixarPdf}
          disabled={baixando}
          className="inline-flex items-center gap-2 font-semibold px-5 py-3 rounded-full bg-primary-gradient text-white shadow-glow hover:brightness-110 disabled:opacity-60 disabled:cursor-not-allowed transition-all"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path
              d="M12 3v13m0 0l-4-4m4 4l4-4M5 21h14"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          {baixando ? 'Preparando…' : 'Baixar PDF'}
        </button>
      </div>

      {/* Aviso LGPD */}
      <div className="rounded-2xl border border-brand-primary/30 bg-brand-primary/[0.08] p-4 mb-8 text-sm text-recorpo-dim">
        {dados.aviso}
      </div>

      {/* Grid de resumo */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-10">
        <Cartao
          rotulo="Peso atual"
          valor={pesoAtual != null ? `${pesoAtual.toFixed(1)} kg` : '—'}
        />
        <Cartao
          rotulo="Meta de peso"
          valor={
            perfil?.metaPesoKg != null ? `${perfil.metaPesoKg.toFixed(1)} kg` : '—'
          }
        />
        <Cartao
          rotulo="Eixo farmacológico"
          valor={perfil?.eixoFarmacologico ?? '—'}
        />
        <Cartao
          rotulo="Última dose (autodecl.)"
          valor={perfil?.ultimaDoseIso ?? '—'}
        />
      </div>

      {/* Logs recentes */}
      <div className="rounded-3xl border border-white/[0.08] bg-recorpo-surface/60 p-6">
        <h2 className="font-serif text-2xl text-recorpo-text mb-4">
          Registros recentes
        </h2>
        {dados.logs.length === 0 && (
          <p className="text-recorpo-dim text-sm">
            Sem registros no período.
          </p>
        )}
        {dados.logs.length > 0 && (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-recorpo-muted border-b border-white/[0.06]">
                  <th className="pb-3 pr-4 font-semibold">Data</th>
                  <th className="pb-3 pr-4 font-semibold">Peso</th>
                  <th className="pb-3 pr-4 font-semibold">Proteína</th>
                  <th className="pb-3 pr-4 font-semibold">Água</th>
                  <th className="pb-3 pr-4 font-semibold">Dose?</th>
                </tr>
              </thead>
              <tbody>
                {dados.logs.slice(0, 20).map((l, i) => (
                  <tr
                    key={i}
                    className="border-b border-white/[0.04] text-recorpo-text/90"
                  >
                    <td className="py-3 pr-4">
                      {new Date(l.data).toLocaleDateString('pt-BR')}
                    </td>
                    <td className="py-3 pr-4">
                      {l.pesoKg != null ? `${l.pesoKg.toFixed(1)} kg` : '—'}
                    </td>
                    <td className="py-3 pr-4">
                      {l.proteinaG != null ? `${l.proteinaG} g` : '—'}
                    </td>
                    <td className="py-3 pr-4">
                      {l.aguaMl != null ? `${(l.aguaMl / 1000).toFixed(1)} L` : '—'}
                    </td>
                    <td className="py-3 pr-4">
                      {l.doseAplicada ? '✓' : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </section>
  );
}

function Cartao({ rotulo, valor }: { rotulo: string; valor: string }) {
  return (
    <div className="rounded-2xl border border-white/[0.08] bg-recorpo-surface/60 p-4">
      <div className="text-[11px] tracking-widest uppercase text-recorpo-muted font-semibold mb-2">
        {rotulo}
      </div>
      <div className="font-serif text-2xl text-recorpo-text truncate">
        {valor}
      </div>
    </div>
  );
}
