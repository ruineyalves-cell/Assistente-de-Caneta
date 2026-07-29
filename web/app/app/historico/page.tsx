'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';

import { api, ApiError, type DailyLog } from '@/lib/app-api-client';
import { useAuth } from '../_lib/auth-provider';
import { Card, EmptyState, ErroBox, Label, Skeleton } from '../_lib/ui';

type Estado =
  | { status: 'loading' }
  | { status: 'ok'; logs: DailyLog[] }
  | { status: 'error'; erro: string };

export default function HistoricoPage() {
  const { estado } = useAuth();
  const [dados, setDados] = useState<Estado>({ status: 'loading' });
  const [nonce, setNonce] = useState(0);

  useEffect(() => {
    if (estado.status !== 'autenticado') return;
    let cancelado = false;
    api
      .listarLogs()
      .then(
        (logs) =>
          !cancelado && setDados({ status: 'ok', logs: ordenarPorData(logs) })
      )
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
  }, [estado.status, nonce]);

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
      <div className="mx-auto max-w-3xl">
        <header className="mb-6 flex items-center justify-between">
          <div>
            <Link
              href="/app"
              className="mb-2 inline-flex items-center gap-1 text-sm text-recorpo-dim hover:text-recorpo-text"
            >
              <span aria-hidden>←</span> Dashboard
            </Link>
            <h1 className="text-2xl font-semibold tracking-tight text-recorpo-text">
              Histórico
            </h1>
          </div>
          <button
            onClick={() => setNonce((n) => n + 1)}
            className="rounded-lg border border-recorpo-border px-3 py-1.5 text-sm text-recorpo-dim hover:border-brand-primary hover:text-recorpo-text"
            aria-label="Atualizar"
          >
            ↻
          </button>
        </header>

        {dados.status === 'loading' && (
          <div className="space-y-3">
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
          </div>
        )}

        {dados.status === 'error' && (
          <ErroBox
            mensagem={`Não deu pra carregar o histórico: ${dados.erro}`}
            onTentar={() => setNonce((n) => n + 1)}
          />
        )}

        {dados.status === 'ok' && dados.logs.length === 0 && (
          <Card>
            <EmptyState
              icone="📭"
              titulo="Nenhum registro ainda"
              descricao="Volte ao dashboard e registre sua primeira dose, água ou peso."
            />
            <div className="mt-4 text-center">
              <Link
                href="/app"
                className="text-sm text-brand-primaryLight hover:underline"
              >
                Ir pro dashboard →
              </Link>
            </div>
          </Card>
        )}

        {dados.status === 'ok' && dados.logs.length > 0 && (
          <div className="space-y-3">
            {agrupar(dados.logs).map(([dataChave, logs]) => (
              <section key={dataChave}>
                <Label>{formatarData(dataChave)}</Label>
                <div className="mt-2 space-y-2">
                  {logs.map((log) => (
                    <ItemLog key={log.id} log={log} />
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

function ItemLog({ log }: { log: DailyLog }) {
  const sintomas = parseSintomas(log.efeitosColaterais);
  return (
    <Card>
      <div className="flex flex-wrap gap-x-4 gap-y-2 text-sm">
        {log.doseAplicada && (
          <span className="rounded-full bg-eixo-streak/15 px-2 py-0.5 text-eixo-streak">
            💊 Dose
          </span>
        )}
        {log.pesoKg != null && (
          <span className="text-recorpo-text">
            ⚖️ {log.pesoKg.toFixed(1)} kg
          </span>
        )}
        {log.aguaMl != null && log.aguaMl > 0 && (
          <span className="text-recorpo-text">💧 {log.aguaMl} ml</span>
        )}
        {log.proteinaG != null && log.proteinaG > 0 && (
          <span className="text-recorpo-text">
            🥚 {log.proteinaG} g proteína
          </span>
        )}
      </div>
      {log.alimentos && (
        <p className="mt-2 text-sm text-recorpo-dim">🍽️ {log.alimentos}</p>
      )}
      {sintomas.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          {sintomas.map((s, i) => (
            <span
              key={i}
              className="rounded-full border border-eixo-sintomas/30 bg-eixo-sintomas/10 px-2 py-0.5 text-xs text-eixo-sintomas"
            >
              🌡️ {s.nome} ({s.intensidade})
            </span>
          ))}
        </div>
      )}
    </Card>
  );
}

function parseSintomas(
  efeitos: string | null
): Array<{ nome: string; intensidade: string }> {
  if (!efeitos) return [];
  try {
    const parsed = JSON.parse(efeitos);
    if (parsed && Array.isArray(parsed.sintomas)) {
      return parsed.sintomas.filter(
        (s: unknown): s is { nome: string; intensidade: string } =>
          typeof (s as { nome?: unknown }).nome === 'string'
      );
    }
  } catch {
    /* string legado, não JSON */
  }
  return [];
}

function ordenarPorData(logs: DailyLog[]): DailyLog[] {
  return [...logs].sort((a, b) => (a.data < b.data ? 1 : -1));
}

function agrupar(logs: DailyLog[]): Array<[string, DailyLog[]]> {
  const mapa = new Map<string, DailyLog[]>();
  for (const l of logs) {
    const chave = l.data.slice(0, 10); // YYYY-MM-DD
    const arr = mapa.get(chave) ?? [];
    arr.push(l);
    mapa.set(chave, arr);
  }
  return Array.from(mapa.entries());
}

function formatarData(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number);
  const data = new Date(y, m - 1, d);
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const diff = Math.floor(
    (hoje.getTime() - data.getTime()) / (1000 * 60 * 60 * 24)
  );
  if (diff === 0) return 'Hoje';
  if (diff === 1) return 'Ontem';
  return data.toLocaleDateString('pt-BR', {
    weekday: 'long',
    day: '2-digit',
    month: 'long',
  });
}
