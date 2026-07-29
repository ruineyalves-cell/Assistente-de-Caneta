'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';

import { api, ApiError } from '@/lib/app-api-client';
import { useAuth } from '../_lib/auth-provider';
import { Card, ErroBox, Label, Skeleton } from '../_lib/ui';

// Espelha PerfilBackend/patientModel.js — campos que backend aceita.
type Perfil = {
  metaPesoKg?: number | null;
  medicacao?: string | null;
  dosagemMg?: number | null;
  frequenciaDoseDias?: number | null;
  metaAguaMl?: number | null;
};

type Estado =
  | { status: 'loading' }
  | { status: 'ok'; perfil: Perfil }
  | { status: 'error'; erro: string };

const MEDICACOES = ['', 'Ozempic', 'Wegovy', 'Mounjaro', 'Saxenda', 'Rybelsus'];

function BotaoRelatorio() {
  const [baixando, setBaixando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  async function baixar() {
    setBaixando(true);
    setErro(null);
    try {
      const blob = await api.baixarMeuRelatorioPdf();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      const dataFmt = new Date().toISOString().slice(0, 10);
      a.download = `recorpo-relatorio-${dataFmt}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (e) {
      setErro(
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro ao baixar'
      );
    } finally {
      setBaixando(false);
    }
  }

  return (
    <>
      <button
        onClick={baixar}
        disabled={baixando}
        className="mt-3 inline-flex items-center gap-2 rounded-lg bg-brand-primary px-4 py-2 text-sm font-medium text-white hover:bg-brand-primaryDark disabled:cursor-not-allowed disabled:opacity-50"
      >
        {baixando ? 'Gerando PDF…' : 'Baixar PDF do médico'}
      </button>
      {erro && (
        <p className="mt-2 text-xs text-eixo-sintomas">{erro}</p>
      )}
    </>
  );
}

export default function PerfilPage() {
  const { estado, logout } = useAuth();
  const [dados, setDados] = useState<Estado>({ status: 'loading' });
  const [salvando, setSalvando] = useState(false);
  const [erroSalvar, setErroSalvar] = useState<string | null>(null);
  const [sucessoSalvar, setSucessoSalvar] = useState(false);

  useEffect(() => {
    if (estado.status !== 'autenticado') return;
    let cancelado = false;
    api
      .obterPerfil()
      .then((p) => !cancelado && setDados({ status: 'ok', perfil: p }))
      .catch((e) => {
        if (cancelado) return;
        setDados({
          status: 'error',
          erro:
            e instanceof ApiError
              ? e.message
              : (e as Error).message ?? 'Erro desconhecido',
        });
      });
    return () => {
      cancelado = true;
    };
  }, [estado.status]);

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

  async function salvar(patch: Partial<Perfil>) {
    if (dados.status !== 'ok') return;
    setSalvando(true);
    setErroSalvar(null);
    setSucessoSalvar(false);
    try {
      const novo = { ...dados.perfil, ...patch };
      await api.salvarPerfil(novo as Record<string, unknown>);
      setDados({ status: 'ok', perfil: novo });
      setSucessoSalvar(true);
      setTimeout(() => setSucessoSalvar(false), 2000);
    } catch (e) {
      setErroSalvar(
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro ao salvar'
      );
    } finally {
      setSalvando(false);
    }
  }

  return (
    <main className="min-h-dvh px-6 py-8 sm:py-10">
      <div className="mx-auto max-w-2xl">
        <header className="mb-6">
          <Link
            href="/app"
            className="mb-2 inline-flex items-center gap-1 text-sm text-recorpo-dim hover:text-recorpo-text"
          >
            <span aria-hidden>←</span> Dashboard
          </Link>
          <h1 className="text-2xl font-semibold tracking-tight text-recorpo-text">
            Perfil
          </h1>
          <p className="mt-1 text-sm text-recorpo-dim">
            {estado.usuario.nome ?? estado.usuario.email} · {estado.usuario.email}
          </p>
        </header>

        {dados.status === 'loading' && (
          <div className="space-y-3">
            <Skeleton className="h-40" />
            <Skeleton className="h-40" />
          </div>
        )}

        {dados.status === 'error' && (
          <ErroBox mensagem={`Não consegui carregar o perfil: ${dados.erro}`} />
        )}

        {dados.status === 'ok' && (
          <div className="space-y-4">
            {/* Meta de peso */}
            <Card>
              <Label>Meta de peso</Label>
              <div className="mt-3 flex items-end gap-3">
                <input
                  type="number"
                  min={30}
                  max={300}
                  step={0.1}
                  defaultValue={dados.perfil.metaPesoKg ?? ''}
                  onBlur={(e) => {
                    const v = Number(e.target.value);
                    if (Number.isFinite(v) && v > 0) salvar({ metaPesoKg: v });
                  }}
                  className="w-32 rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-eixo-peso focus:ring-2 focus:ring-eixo-peso/30"
                />
                <span className="pb-2.5 text-sm text-recorpo-dim">kg</span>
              </div>
            </Card>

            {/* Medicação */}
            <Card>
              <Label>Medicação GLP-1</Label>
              <div className="mt-3 grid grid-cols-2 gap-3">
                <select
                  defaultValue={dados.perfil.medicacao ?? ''}
                  onChange={(e) => salvar({ medicacao: e.target.value || null })}
                  className="rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-brand-primaryLight"
                >
                  {MEDICACOES.map((m) => (
                    <option key={m || 'nenhum'} value={m}>
                      {m || 'Nenhuma'}
                    </option>
                  ))}
                </select>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    min={0}
                    step={0.25}
                    placeholder="Dose"
                    defaultValue={dados.perfil.dosagemMg ?? ''}
                    onBlur={(e) => {
                      const v = Number(e.target.value);
                      salvar({
                        dosagemMg:
                          Number.isFinite(v) && v > 0 ? v : null,
                      });
                    }}
                    className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-brand-primaryLight"
                  />
                  <span className="text-sm text-recorpo-dim">mg</span>
                </div>
              </div>
              <label className="mt-3 flex items-center gap-2 text-sm text-recorpo-dim">
                Frequência (dias):
                <input
                  type="number"
                  min={1}
                  max={30}
                  defaultValue={dados.perfil.frequenciaDoseDias ?? 7}
                  onBlur={(e) => {
                    const v = Number(e.target.value);
                    if (Number.isFinite(v) && v > 0)
                      salvar({ frequenciaDoseDias: Math.round(v) });
                  }}
                  className="w-16 rounded-lg border border-recorpo-border bg-recorpo-bg px-2 py-1 text-recorpo-text outline-none focus:border-brand-primaryLight"
                />
              </label>
            </Card>

            {/* Meta de água */}
            <Card>
              <Label>Meta de hidratação diária</Label>
              <div className="mt-3 flex items-end gap-3">
                <input
                  type="number"
                  min={500}
                  max={5000}
                  step={100}
                  defaultValue={dados.perfil.metaAguaMl ?? 2500}
                  onBlur={(e) => {
                    const v = Number(e.target.value);
                    if (Number.isFinite(v) && v > 0)
                      salvar({ metaAguaMl: Math.round(v) });
                  }}
                  className="w-32 rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-eixo-agua focus:ring-2 focus:ring-eixo-agua/30"
                />
                <span className="pb-2.5 text-sm text-recorpo-dim">ml</span>
              </div>
            </Card>

            {salvando && (
              <p className="text-xs text-recorpo-dim">Salvando…</p>
            )}
            {sucessoSalvar && (
              <p className="text-xs text-eixo-peso">✓ Salvo</p>
            )}
            {erroSalvar && (
              <ErroBox mensagem={`Não deu pra salvar: ${erroSalvar}`} />
            )}

            <Card>
              <Label>Relatório médico</Label>
              <p className="mt-2 text-sm text-recorpo-text">
                PDF com seus últimos 90 dias — leve pro médico na consulta.
              </p>
              <BotaoRelatorio />
            </Card>

            <Card>
              <Label>Meus dados (LGPD)</Label>
              <p className="mt-2 text-sm text-recorpo-text">
                Exportar em JSON, ver trilha de acessos, excluir sua conta.
              </p>
              <Link
                href="/app/meus-dados"
                className="mt-3 inline-block rounded-lg border border-recorpo-border px-4 py-2 text-sm text-recorpo-text hover:border-brand-primary hover:bg-recorpo-surfaceHi"
              >
                Abrir meus dados →
              </Link>
            </Card>

            <Card>
              <Label>Sessão</Label>
              <div className="mt-3">
                <button
                  onClick={logout}
                  className="w-full rounded-lg border border-eixo-sintomas/40 py-2.5 text-sm text-eixo-sintomas hover:bg-eixo-sintomas/10"
                >
                  Sair
                </button>
              </div>
            </Card>
          </div>
        )}
      </div>
    </main>
  );
}
