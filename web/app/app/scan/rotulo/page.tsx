'use client';

import Link from 'next/link';
import { useState } from 'react';

import { api, ApiError } from '@/lib/app-api-client';
import { useAuth } from '../../_lib/auth-provider';
import { CameraCapture } from '../../_lib/camera-capture';
import { Card, ErroBox, Label } from '../../_lib/ui';

type ResultadoRotulo = {
  iaConfigurada?: boolean;
  mensagem?: string;
  produto?: string | null;
  porcao?: string | null;
  caloriasKcal?: number | null;
  proteinaG?: number | null;
  carboidratosG?: number | null;
  gordurasG?: number | null;
  gordurasSaturadasG?: number | null;
  fibraG?: number | null;
  sodioMg?: number | null;
  confianca?: number;
};

export default function ScanRotuloPage() {
  const { estado } = useAuth();
  const [analisando, setAnalisando] = useState(false);
  const [resultado, setResultado] = useState<ResultadoRotulo | null>(null);
  const [erro, setErro] = useState<string | null>(null);

  async function analisar(imagemBase64: string) {
    setAnalisando(true);
    setErro(null);
    try {
      const r = (await api.analisarRotuloIA(imagemBase64)) as ResultadoRotulo;
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
          Scanner de rótulo
        </h1>
        <p className="mt-1 text-sm text-recorpo-dim">
          Fotografe a tabela nutricional — a IA transcreve macronutrientes por
          porção.
        </p>

        <div className="mt-6">
          {analisando ? (
            <Card>
              <div className="flex items-center gap-3 py-8">
                <div className="h-6 w-6 animate-spin rounded-full border-2 border-recorpo-border border-t-brand-primaryLight" />
                <span className="text-sm text-recorpo-text">
                  Lendo a tabela nutricional…
                </span>
              </div>
            </Card>
          ) : resultado ? (
            <ResultadoCard
              resultado={resultado}
              onRefazer={() => {
                setResultado(null);
                setErro(null);
              }}
            />
          ) : (
            <CameraCapture
              onCaptura={analisar}
              onCancelar={() => history.back()}
              hint="Enquadre a tabela nutricional bem iluminada, sem reflexos e reta pra IA ler os números."
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
  onRefazer,
}: {
  resultado: ResultadoRotulo;
  onRefazer: () => void;
}) {
  if (resultado.iaConfigurada === false) {
    return (
      <Card>
        <p className="text-sm text-recorpo-text">
          {resultado.mensagem ?? 'IA indisponível.'}
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
  const semDados = !resultado.produto && !resultado.caloriasKcal;

  return (
    <Card eixo="refeicao">
      <Label>Tabela nutricional</Label>
      {semDados ? (
        <p className="mt-2 text-sm text-recorpo-text">
          Não consegui ler o rótulo. Refaça a foto com boa luz e sem reflexos.
        </p>
      ) : (
        <>
          <h2 className="mt-2 text-xl font-semibold text-recorpo-text">
            {resultado.produto ?? 'Produto identificado'}
          </h2>
          {resultado.porcao && (
            <p className="mt-1 text-sm text-recorpo-dim">
              Porção de referência: {resultado.porcao}
            </p>
          )}
          <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
            <Linha label="Calorias" valor={resultado.caloriasKcal} unidade="kcal" />
            <Linha label="Proteína" valor={resultado.proteinaG} unidade="g" />
            <Linha label="Carboidratos" valor={resultado.carboidratosG} unidade="g" />
            <Linha label="Gorduras" valor={resultado.gordurasG} unidade="g" />
            <Linha
              label="Gord. sat."
              valor={resultado.gordurasSaturadasG}
              unidade="g"
            />
            <Linha label="Fibra" valor={resultado.fibraG} unidade="g" />
            <Linha label="Sódio" valor={resultado.sodioMg} unidade="mg" />
          </dl>
          <p className="mt-3 text-xs text-recorpo-muted">
            Confiança: {confianca}% · transcrição direta do rótulo, sem
            interpretação clínica.
          </p>
        </>
      )}

      <button
        onClick={onRefazer}
        className="mt-4 w-full rounded-lg border border-recorpo-border py-2.5 text-sm text-recorpo-text hover:bg-recorpo-surfaceHi"
      >
        Ler outro rótulo
      </button>
    </Card>
  );
}

function Linha({
  label,
  valor,
  unidade,
}: {
  label: string;
  valor: number | null | undefined;
  unidade: string;
}) {
  return (
    <div className="rounded-lg border border-recorpo-border p-2.5">
      <dt className="text-[10px] font-semibold uppercase tracking-wider text-recorpo-dim">
        {label}
      </dt>
      <dd className="mt-1 flex items-baseline gap-1">
        <span className="text-lg font-semibold tabular-nums text-recorpo-text">
          {valor ?? '—'}
        </span>
        <span className="text-xs text-recorpo-dim">{unidade}</span>
      </dd>
    </div>
  );
}
