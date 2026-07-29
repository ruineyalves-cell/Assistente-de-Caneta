'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';

import { api, ApiError } from '@/lib/app-api-client';
import { useAuth } from '../_lib/auth-provider';
import { Card, EmptyState, ErroBox, Label, Skeleton } from '../_lib/ui';

type Acesso = {
  id?: string;
  action?: string;
  resource?: string;
  actor_role?: string | null;
  ip?: string | null;
  created_at?: string;
};

type EstadoAcessos =
  | { status: 'loading' }
  | { status: 'ok'; acessos: Acesso[] }
  | { status: 'error'; erro: string };

export default function MeusDadosPage() {
  const { estado, logout } = useAuth();
  const [acessos, setAcessos] = useState<EstadoAcessos>({ status: 'loading' });
  const [baixando, setBaixando] = useState(false);
  const [erroBaixar, setErroBaixar] = useState<string | null>(null);
  const [excluindo, setExcluindo] = useState(false);
  const [erroExcluir, setErroExcluir] = useState<string | null>(null);
  const [confirmacao, setConfirmacao] = useState<'idle' | 'passo1' | 'passo2'>(
    'idle'
  );
  const [textoConfirma, setTextoConfirma] = useState('');

  useEffect(() => {
    if (estado.status !== 'autenticado') return;
    let cancelado = false;
    api
      .listarAcessos()
      .then((r) => {
        if (cancelado) return;
        setAcessos({ status: 'ok', acessos: r as Acesso[] });
      })
      .catch((e) => {
        if (cancelado) return;
        setAcessos({
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

  async function baixarDados() {
    setBaixando(true);
    setErroBaixar(null);
    try {
      const json = await api.exportarDados();
      const blob = new Blob([JSON.stringify(json, null, 2)], {
        type: 'application/json',
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      const dataFmt = new Date().toISOString().slice(0, 10);
      a.download = `recorpo-meus-dados-${dataFmt}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (e) {
      setErroBaixar(
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro ao baixar'
      );
    } finally {
      setBaixando(false);
    }
  }

  async function confirmarExclusao() {
    if (textoConfirma.trim().toUpperCase() !== 'EXCLUIR') return;
    setExcluindo(true);
    setErroExcluir(null);
    try {
      await api.excluirConta();
      // Sucesso: sessão morreu no servidor, deslogamos localmente.
      await logout();
    } catch (e) {
      setErroExcluir(
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro ao excluir'
      );
      setExcluindo(false);
    }
  }

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
            Meus dados
          </h1>
          <p className="mt-1 text-sm text-recorpo-dim">
            Seus direitos sobre os dados que você compartilhou com o Recorpo,
            garantidos pela LGPD.
          </p>
        </header>

        <div className="space-y-4">
          {/* Exportar */}
          <Card>
            <div className="flex items-start justify-between gap-4">
              <div>
                <Label>Exportar meus dados</Label>
                <p className="mt-2 text-sm text-recorpo-text">
                  Baixe um arquivo JSON com tudo que você registrou: perfil,
                  logs diários, sintomas e consentimentos.
                </p>
                <p className="mt-1 text-xs text-recorpo-muted">
                  Formato aberto pra você guardar, transferir pra outro app ou
                  levar ao médico.
                </p>
              </div>
              <span className="text-3xl" aria-hidden>
                📦
              </span>
            </div>
            <button
              onClick={baixarDados}
              disabled={baixando}
              className="mt-4 w-full rounded-lg bg-brand-primary py-2.5 text-sm font-medium text-white hover:bg-brand-primaryDark disabled:cursor-not-allowed disabled:opacity-50"
            >
              {baixando ? 'Preparando arquivo…' : 'Baixar meus dados (JSON)'}
            </button>
            {erroBaixar && (
              <p className="mt-2 text-xs text-eixo-sintomas">{erroBaixar}</p>
            )}
          </Card>

          {/* Acessos */}
          <Card>
            <div className="flex items-start justify-between gap-4">
              <div>
                <Label>Quem viu meus dados</Label>
                <p className="mt-2 text-sm text-recorpo-text">
                  Trilha de auditoria (LGPD art. 37). Cada leitura, escrita ou
                  export dos seus dados de saúde fica registrada.
                </p>
              </div>
              <span className="text-3xl" aria-hidden>
                👁️
              </span>
            </div>
            <div className="mt-4">
              {acessos.status === 'loading' && (
                <div className="space-y-2">
                  <Skeleton className="h-4 w-full" />
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-4 w-1/2" />
                </div>
              )}
              {acessos.status === 'error' && (
                <ErroBox mensagem={`Não deu pra carregar: ${acessos.erro}`} />
              )}
              {acessos.status === 'ok' && acessos.acessos.length === 0 && (
                <EmptyState
                  icone="📄"
                  titulo="Sem acessos registrados ainda"
                  descricao="Assim que você ou seu médico acessar dados, aparecerá aqui."
                />
              )}
              {acessos.status === 'ok' && acessos.acessos.length > 0 && (
                <div className="max-h-60 overflow-y-auto rounded-lg border border-recorpo-border">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-recorpo-surfaceHi text-recorpo-dim">
                      <tr>
                        <th className="px-3 py-2">Quando</th>
                        <th className="px-3 py-2">Ação</th>
                        <th className="px-3 py-2">Recurso</th>
                        <th className="px-3 py-2">Por</th>
                      </tr>
                    </thead>
                    <tbody className="text-recorpo-text">
                      {acessos.acessos.slice(0, 50).map((a, i) => (
                        <tr
                          key={a.id ?? i}
                          className="border-t border-recorpo-border/60"
                        >
                          <td className="px-3 py-1.5 font-mono text-[10px] text-recorpo-dim">
                            {formatarData(a.created_at)}
                          </td>
                          <td className="px-3 py-1.5">{a.action ?? '—'}</td>
                          <td className="px-3 py-1.5">{a.resource ?? '—'}</td>
                          <td className="px-3 py-1.5 text-recorpo-dim">
                            {a.actor_role ?? 'você'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </Card>

          {/* Excluir conta */}
          <Card className="border-l-4 border-l-eixo-sintomas/70">
            <div className="flex items-start justify-between gap-4">
              <div>
                <Label>Excluir conta e todos os dados</Label>
                <p className="mt-2 text-sm text-recorpo-text">
                  Apaga permanentemente sua conta, logs, perfil e histórico.
                  <strong> Ação irreversível.</strong>
                </p>
                <p className="mt-1 text-xs text-recorpo-muted">
                  LGPD art. 18 VI · você tem direito à eliminação dos dados
                  quando quiser.
                </p>
              </div>
              <span className="text-3xl" aria-hidden>
                🗑️
              </span>
            </div>

            {confirmacao === 'idle' && (
              <button
                onClick={() => setConfirmacao('passo1')}
                className="mt-4 w-full rounded-lg border border-eixo-sintomas/50 py-2.5 text-sm text-eixo-sintomas hover:bg-eixo-sintomas/10"
              >
                Quero excluir minha conta
              </button>
            )}

            {confirmacao === 'passo1' && (
              <div className="mt-4 rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/5 p-4">
                <p className="text-sm text-recorpo-text">
                  Antes de excluir, considere <strong>baixar seus dados</strong>{' '}
                  no botão acima. Depois de excluir, a informação é destruída
                  e não pode ser recuperada.
                </p>
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={() => setConfirmacao('idle')}
                    className="flex-1 rounded-lg border border-recorpo-border py-2 text-sm text-recorpo-dim hover:text-recorpo-text"
                  >
                    Cancelar
                  </button>
                  <button
                    onClick={() => setConfirmacao('passo2')}
                    className="flex-1 rounded-lg border border-eixo-sintomas/60 py-2 text-sm text-eixo-sintomas hover:bg-eixo-sintomas/10"
                  >
                    Continuar
                  </button>
                </div>
              </div>
            )}

            {confirmacao === 'passo2' && (
              <div className="mt-4 rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/5 p-4">
                <p className="text-sm text-recorpo-text">
                  Pra confirmar, digite <code className="rounded bg-recorpo-bg px-1.5 py-0.5 text-eixo-sintomas">EXCLUIR</code>{' '}
                  no campo abaixo:
                </p>
                <input
                  type="text"
                  value={textoConfirma}
                  onChange={(e) => setTextoConfirma(e.target.value)}
                  placeholder="EXCLUIR"
                  autoCapitalize="characters"
                  className="mt-3 w-full rounded-lg border border-eixo-sintomas/40 bg-recorpo-bg px-3 py-2 text-recorpo-text uppercase outline-none focus:border-eixo-sintomas"
                />
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={() => {
                      setConfirmacao('idle');
                      setTextoConfirma('');
                    }}
                    className="flex-1 rounded-lg border border-recorpo-border py-2 text-sm text-recorpo-dim hover:text-recorpo-text"
                  >
                    Cancelar
                  </button>
                  <button
                    onClick={confirmarExclusao}
                    disabled={
                      excluindo ||
                      textoConfirma.trim().toUpperCase() !== 'EXCLUIR'
                    }
                    className="flex-1 rounded-lg bg-eixo-sintomas py-2 text-sm font-medium text-white hover:bg-eixo-sintomasDark disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {excluindo ? 'Excluindo…' : 'Excluir agora'}
                  </button>
                </div>
                {erroExcluir && (
                  <p className="mt-2 text-xs text-eixo-sintomas">{erroExcluir}</p>
                )}
              </div>
            )}
          </Card>
        </div>
      </div>
    </main>
  );
}

function formatarData(iso: string | undefined): string {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return iso;
  }
}
