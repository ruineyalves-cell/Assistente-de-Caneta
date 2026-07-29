'use client';

import Link from 'next/link';
import { useState } from 'react';

import { api, ApiError } from '@/lib/app-api-client';
import { useAuth } from '../../_lib/auth-provider';
import { CameraCapture } from '../../_lib/camera-capture';
import { Card, ErroBox, Label } from '../../_lib/ui';

type ResultadoBula = {
  iaConfigurada?: boolean;
  mensagem?: string;
  medicamento?: string | null;
  principioAtivo?: string | null;
  indicacoes?: string[];
  dose?: string | null;
  efeitosComuns?: string[];
  alertas?: string[];
  confianca?: number;
};

export default function ScanBulaPage() {
  const { estado } = useAuth();
  const [analisando, setAnalisando] = useState(false);
  const [resultado, setResultado] = useState<ResultadoBula | null>(null);
  const [erro, setErro] = useState<string | null>(null);

  async function analisar(imagemBase64: string) {
    setAnalisando(true);
    setErro(null);
    try {
      const r = (await api.analisarBulaIA(imagemBase64)) as ResultadoBula;
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
          Bula do medicamento
        </h1>
        <p className="mt-1 text-sm text-recorpo-dim">
          Fotografe a bula — a IA transcreve indicações, doses, efeitos e
          alertas. Não substitui orientação médica.
        </p>

        <div className="mt-6">
          {analisando ? (
            <Card>
              <div className="flex items-center gap-3 py-8">
                <div className="h-6 w-6 animate-spin rounded-full border-2 border-recorpo-border border-t-brand-primaryLight" />
                <span className="text-sm text-recorpo-text">
                  Transcrevendo a bula…
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
              hint="Foque no cabeçalho (nome + princípio ativo) ou na seção que você quer entender."
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
  resultado: ResultadoBula;
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
  const semDados =
    !resultado.medicamento &&
    !resultado.principioAtivo &&
    !(resultado.indicacoes?.length);

  return (
    <div className="space-y-4">
      {semDados ? (
        <Card>
          <p className="text-sm text-recorpo-text">
            Não consegui identificar a bula. Refaça com boa luz e enquadre o
            cabeçalho da bula.
          </p>
        </Card>
      ) : (
        <>
          <Card>
            <Label>Medicamento</Label>
            <h2 className="mt-2 text-xl font-semibold text-recorpo-text">
              {resultado.medicamento ?? '—'}
            </h2>
            {resultado.principioAtivo && (
              <p className="mt-1 text-sm text-recorpo-dim">
                Princípio ativo: {resultado.principioAtivo}
              </p>
            )}
            {resultado.dose && (
              <p className="mt-2 text-sm text-recorpo-text">
                <strong>Dose:</strong> {resultado.dose}
              </p>
            )}
          </Card>

          <Secao titulo="Indicações" itens={resultado.indicacoes} />
          <Secao titulo="Efeitos comuns" itens={resultado.efeitosComuns} />
          <Secao
            titulo="Alertas e contraindicações"
            itens={resultado.alertas}
            destaque
          />

          <p className="text-center text-xs text-recorpo-muted">
            Confiança: {confianca}% · transcrição direta da bula. Sempre
            confirme com seu médico ou farmacêutico.
          </p>
        </>
      )}

      <button
        onClick={onRefazer}
        className="w-full rounded-lg border border-recorpo-border py-2.5 text-sm text-recorpo-text hover:bg-recorpo-surfaceHi"
      >
        Ler outra bula
      </button>
    </div>
  );
}

function Secao({
  titulo,
  itens,
  destaque = false,
}: {
  titulo: string;
  itens?: string[];
  destaque?: boolean;
}) {
  if (!itens || itens.length === 0) return null;
  return (
    <Card
      className={
        destaque ? 'border-l-4 border-l-eixo-sintomas/70' : undefined
      }
    >
      <Label>{titulo}</Label>
      <ul className="mt-2 space-y-1.5 text-sm text-recorpo-text">
        {itens.map((s, i) => (
          <li key={i} className="flex gap-2">
            <span
              className={
                destaque ? 'text-eixo-sintomas' : 'text-brand-primaryLight'
              }
              aria-hidden
            >
              •
            </span>
            <span>{s}</span>
          </li>
        ))}
      </ul>
    </Card>
  );
}
