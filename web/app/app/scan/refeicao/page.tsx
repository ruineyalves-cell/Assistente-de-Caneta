'use client';

import Link from 'next/link';
import { useState } from 'react';

import { api, ApiError } from '@/lib/app-api-client';
import { useAuth } from '../../_lib/auth-provider';
import { CameraCapture } from '../../_lib/camera-capture';
import { Card, ErroBox, Kpi, Label } from '../../_lib/ui';

type ResultadoRefeicao = {
  iaConfigurada?: boolean;
  mensagem?: string;
  titulo?: string | null;
  descricao?: string | null;
  proteinaEstimadaG?: number | null;
  aguaEstimadaMl?: number | null;
  confianca?: number;
};

export default function ScanRefeicaoPage() {
  const { estado } = useAuth();
  const [analisando, setAnalisando] = useState(false);
  const [resultado, setResultado] = useState<ResultadoRefeicao | null>(null);
  const [erro, setErro] = useState<string | null>(null);
  const [salvando, setSalvando] = useState(false);
  const [salvo, setSalvo] = useState(false);

  async function analisar(imagemBase64: string) {
    setAnalisando(true);
    setErro(null);
    setResultado(null);
    try {
      const r = (await api.analisarRefeicaoIA(imagemBase64)) as ResultadoRefeicao;
      setResultado(r);
    } catch (e) {
      setErro(
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro desconhecido'
      );
    } finally {
      setAnalisando(false);
    }
  }

  async function salvarRegistro() {
    if (!resultado) return;
    setSalvando(true);
    try {
      await api.registrarLog({
        data: new Date().toISOString(),
        alimentos: resultado.titulo ?? resultado.descricao ?? 'Refeição',
        proteinaG: resultado.proteinaEstimadaG ?? undefined,
        aguaMl: resultado.aguaEstimadaMl ?? undefined,
      } as any);
      setSalvo(true);
    } catch (e) {
      setErro(
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro ao salvar'
      );
    } finally {
      setSalvando(false);
    }
  }

  if (estado.status !== 'autenticado') {
    return (
      <main className="grid min-h-dvh place-items-center">
        <div
          className="h-8 w-8 animate-spin rounded-full border-2 border-recorpo-border border-t-brand-primaryLight"
          role="status"
        />
      </main>
    );
  }

  return (
    <main className="min-h-dvh px-6 py-8 sm:py-10">
      <div className="mx-auto max-w-lg">
        <Link
          href="/app"
          className="mb-4 inline-flex items-center gap-1 text-sm text-recorpo-dim hover:text-recorpo-text"
        >
          <span aria-hidden>←</span> Dashboard
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight text-recorpo-text">
          Scanner de refeição
        </h1>
        <p className="mt-1 text-sm text-recorpo-dim">
          Tire uma foto do seu prato — a IA identifica o alimento e estima a
          proteína.
        </p>

        <div className="mt-6">
          {analisando ? (
            <Card>
              <div className="flex items-center gap-3 py-8">
                <div className="h-6 w-6 animate-spin rounded-full border-2 border-recorpo-border border-t-brand-primaryLight" />
                <span className="text-sm text-recorpo-text">
                  Analisando com IA… pode levar até 30 segundos.
                </span>
              </div>
            </Card>
          ) : resultado ? (
            <ResultadoCard
              resultado={resultado}
              erro={erro}
              salvando={salvando}
              salvo={salvo}
              onSalvar={salvarRegistro}
              onRefazer={() => {
                setResultado(null);
                setErro(null);
                setSalvo(false);
              }}
            />
          ) : (
            <CameraCapture
              onCaptura={analisar}
              onCancelar={() => history.back()}
              hint="Enquadre o prato inteiro, boa luz. Sem talheres cobrindo os alimentos."
            />
          )}
          {erro && !resultado && <ErroBox mensagem={erro} />}
        </div>
      </div>
    </main>
  );
}

function ResultadoCard({
  resultado,
  erro,
  salvando,
  salvo,
  onSalvar,
  onRefazer,
}: {
  resultado: ResultadoRefeicao;
  erro: string | null;
  salvando: boolean;
  salvo: boolean;
  onSalvar: () => void;
  onRefazer: () => void;
}) {
  if (resultado.iaConfigurada === false) {
    return (
      <Card>
        <p className="text-sm text-recorpo-text">
          {resultado.mensagem ??
            'IA de análise indisponível no servidor no momento.'}
        </p>
        <button
          onClick={onRefazer}
          className="mt-4 w-full rounded-lg border border-recorpo-border py-2.5 text-sm text-recorpo-text hover:bg-recorpo-surfaceHi"
        >
          Tentar de novo
        </button>
      </Card>
    );
  }

  const confianca = Math.round((resultado.confianca ?? 0) * 100);
  const naoParece =
    !resultado.titulo && resultado.descricao?.toLowerCase().includes('não parece');

  return (
    <Card eixo="refeicao">
      <Label>Análise IA</Label>
      {naoParece ? (
        <p className="mt-2 text-sm text-recorpo-text">
          {resultado.descricao} Tente uma foto diferente ou mais próxima do prato.
        </p>
      ) : (
        <>
          <h2 className="mt-2 text-xl font-semibold text-recorpo-text">
            {resultado.titulo ?? 'Refeição identificada'}
          </h2>
          {resultado.descricao && (
            <p className="mt-1 text-sm text-recorpo-dim">
              {resultado.descricao}
            </p>
          )}
          <div className="mt-4 grid grid-cols-2 gap-3">
            <div className="rounded-lg border border-recorpo-border p-3">
              <Kpi
                valor={resultado.proteinaEstimadaG ?? '—'}
                unidade="g proteína"
              />
            </div>
            <div className="rounded-lg border border-recorpo-border p-3">
              <Kpi
                valor={resultado.aguaEstimadaMl ?? '—'}
                unidade="ml bebida"
              />
            </div>
          </div>
          <p className="mt-3 text-xs text-recorpo-muted">
            Confiança da IA: {confianca}% · valores estimados, ajuste se necessário.
          </p>
        </>
      )}

      {erro && (
        <p className="mt-3 rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/10 px-3 py-2 text-sm text-eixo-sintomas">
          {erro}
        </p>
      )}

      <div className="mt-4 flex gap-2">
        <button
          onClick={onRefazer}
          className="flex-1 rounded-lg border border-recorpo-border py-2.5 text-sm text-recorpo-text hover:bg-recorpo-surfaceHi"
        >
          Refazer
        </button>
        {!naoParece && !salvo && (
          <button
            onClick={onSalvar}
            disabled={salvando}
            className="flex-1 rounded-lg bg-brand-primary py-2.5 text-sm font-medium text-white hover:bg-brand-primaryDark disabled:opacity-50"
          >
            {salvando ? 'Salvando…' : 'Salvar no histórico'}
          </button>
        )}
        {salvo && (
          <Link
            href="/app"
            className="flex-1 rounded-lg bg-eixo-peso py-2.5 text-center text-sm font-medium text-white"
          >
            ✓ Salvo · Voltar ao dashboard
          </Link>
        )}
      </div>
    </Card>
  );
}
