'use client';

import { Suspense, useEffect, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useAuth } from './_lib/auth-provider';
import { useDashboardData } from './_lib/dashboard-data';
import {
  AguaSheet,
  DoseSheet,
  PesoSheet,
  RefeicaoSheet,
  SintomasSheet,
} from './_lib/sheets';
import { Card, ErroBox, Kpi, Label, Skeleton, EmptyState } from './_lib/ui';

type TipoSheet = 'dose' | 'agua' | 'peso' | 'refeicao' | 'sintomas' | null;

/**
 * Next 14 exige que useSearchParams() esteja dentro de <Suspense>. Sem
 * isso o build falha com "missing-suspense-with-csr-bailout". Como o
 * dashboard inteiro usa o hook (pro deep-link do PWA), o export
 * default só envelopa o conteúdo real em Suspense.
 */
export default function AppDashboardPage() {
  return (
    <Suspense fallback={<TelaCarregando />}>
      <DashboardConteudo />
    </Suspense>
  );
}

function TelaCarregando() {
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

function DashboardConteudo() {
  const { estado, logout } = useAuth();
  const accessToken =
    estado.status === 'autenticado' ? estado.accessToken : null;
  const { dashboard, resumo, alertas, logsHoje, reload } =
    useDashboardData(accessToken);
  const [sheetAberto, setSheetAberto] = useState<TipoSheet>(null);
  const abrir = (t: Exclude<TipoSheet, null>) => setSheetAberto(t);
  const fechar = () => setSheetAberto(null);
  const aoRegistrar = () => {
    reload();
  };

  // Deep-link do PWA shortcut: /app?acao=dose|agua|peso|refeicao|sintomas
  // abre o sheet correspondente direto. Só reage 1× por load pra evitar
  // reabrir o modal quando o user já fechou manualmente.
  const searchParams = useSearchParams();
  useEffect(() => {
    if (estado.status !== 'autenticado') return;
    const acao = searchParams.get('acao');
    if (!acao) return;
    if (['dose', 'agua', 'peso', 'refeicao', 'sintomas'].includes(acao)) {
      setSheetAberto(acao as Exclude<TipoSheet, null>);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
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

  const primeiroNome =
    (estado.usuario.nome ?? estado.usuario.email).split(' ')[0].split('@')[0];

  return (
    <main className="min-h-dvh px-6 py-8 sm:py-10">
      <div className="mx-auto max-w-3xl">
        <Header nome={primeiroNome} onLogout={logout} onReload={reload} />

        {/* Banner de alertas — só aparece se backend detectou algo */}
        {alertas.status === 'ok' && alertas.data.length > 0 && (
          <div className="mt-6 space-y-2">
            {alertas.data.slice(0, 3).map((a, i) => (
              <div
                key={i}
                className="rounded-xl border border-eixo-streak/40 bg-eixo-streak/10 p-4 text-sm text-recorpo-text"
              >
                <span className="mr-2">⚠️</span>
                {String((a as { mensagem?: string }).mensagem ?? '—')}
              </div>
            ))}
          </div>
        )}

        {/* Streak + Score */}
        <section className="mt-6 grid gap-4 sm:grid-cols-2">
          {dashboard.status === 'loading' && (
            <>
              <SkeletonCard />
              <SkeletonCard />
            </>
          )}
          {dashboard.status === 'error' && (
            <div className="sm:col-span-2">
              <ErroBox
                mensagem={`Não deu pra carregar seu resumo: ${dashboard.erro}`}
                onTentar={reload}
              />
            </div>
          )}
          {dashboard.status === 'ok' && (
            <>
              <Card eixo="streak">
                <Label>Sequência atual</Label>
                <div className="mt-2 flex items-center gap-3">
                  <span className="text-4xl" aria-hidden>
                    🔥
                  </span>
                  <Kpi
                    valor={dashboard.data.streak}
                    unidade="dias"
                    hint="registrando todos os dias"
                  />
                </div>
              </Card>
              <Card>
                <Label>Score de hoje</Label>
                <div className="mt-2">
                  <Kpi
                    valor={
                      dashboard.data.scores28dias[0]?.score ?? 0
                    }
                    unidade="/ 100"
                    hint={`${dashboard.data.scores28dias.length} dias registrados nos últimos 28`}
                  />
                </div>
              </Card>
            </>
          )}
        </section>

        {/* Resumo do dia */}
        <section className="mt-4">
          {resumo.status === 'loading' && <SkeletonCard tall />}
          {resumo.status === 'ok' && <ResumoDoDia data={resumo.data} />}
          {/* Erro no resumo cai silencioso — não é bloqueador */}
        </section>

        {/* Logs de hoje */}
        <section className="mt-4">
          <div className="mb-2 flex items-baseline justify-between">
            <Label>Registros de hoje</Label>
            {logsHoje.status === 'ok' && logsHoje.data.length > 0 && (
              <a
                href="/app/historico"
                className="text-xs text-brand-primaryLight hover:underline"
              >
                Ver histórico completo →
              </a>
            )}
          </div>
          {logsHoje.status === 'loading' && <SkeletonCard />}
          {logsHoje.status === 'ok' && logsHoje.data.length === 0 && (
            <Card>
              <EmptyState
                icone="📝"
                titulo="Nada registrado hoje ainda"
                descricao="Use os botões abaixo pra logar dose, hidratação, peso, refeição ou sintomas."
              />
            </Card>
          )}
          {logsHoje.status === 'ok' && logsHoje.data.length > 0 && (
            <Card className="space-y-2 text-sm">
              {logsHoje.data.map((l) => (
                <div
                  key={l.id}
                  className="flex flex-wrap gap-x-4 gap-y-1 border-b border-recorpo-border/60 pb-2 last:border-0 last:pb-0"
                >
                  {l.doseAplicada && (
                    <span className="text-recorpo-text">💊 Dose</span>
                  )}
                  {l.pesoKg != null && (
                    <span className="text-recorpo-text">
                      ⚖️ {l.pesoKg.toFixed(1)} kg
                    </span>
                  )}
                  {l.aguaMl != null && l.aguaMl > 0 && (
                    <span className="text-recorpo-text">💧 {l.aguaMl} ml</span>
                  )}
                  {l.proteinaG != null && l.proteinaG > 0 && (
                    <span className="text-recorpo-text">
                      🥚 {l.proteinaG} g proteína
                    </span>
                  )}
                  {l.alimentos && (
                    <span className="text-recorpo-dim">🍽️ {l.alimentos}</span>
                  )}
                </div>
              ))}
            </Card>
          )}
        </section>

        {/* Ações rápidas */}
        <section className="mt-6">
          <Label>Registrar</Label>
          <div className="mt-2 grid grid-cols-2 gap-3 sm:grid-cols-3">
            <AcaoRapida icone="💊" titulo="Dose" onClick={() => abrir('dose')} />
            <AcaoRapida icone="💧" titulo="Água" onClick={() => abrir('agua')} />
            <AcaoRapida icone="⚖️" titulo="Peso" onClick={() => abrir('peso')} />
            <AcaoRapida
              icone="🍽️"
              titulo="Refeição"
              onClick={() => abrir('refeicao')}
            />
            <AcaoRapida
              icone="🌡️"
              titulo="Sintomas"
              onClick={() => abrir('sintomas')}
            />
            <AcaoRapida
              icone="📄"
              titulo="Relatório"
              hint="PDF"
              href="/app/perfil#relatorio"
            />
          </div>
        </section>

        {/* Scanners IA — separados porque abrem página inteira (câmera) */}
        <section className="mt-6">
          <Label>Scanner com IA</Label>
          <div className="mt-2 grid grid-cols-3 gap-3">
            <AcaoRapida icone="📸" titulo="Refeição" href="/app/scan/refeicao" />
            <AcaoRapida icone="🏷️" titulo="Rótulo" href="/app/scan/rotulo" />
            <AcaoRapida icone="💉" titulo="Bula" href="/app/scan/bula" />
          </div>
        </section>

        {/* Sheets — só um pode ficar aberto por vez */}
        <DoseSheet
          aberto={sheetAberto === 'dose'}
          onFechar={fechar}
          onSucesso={aoRegistrar}
        />
        <AguaSheet
          aberto={sheetAberto === 'agua'}
          onFechar={fechar}
          onSucesso={aoRegistrar}
        />
        <PesoSheet
          aberto={sheetAberto === 'peso'}
          onFechar={fechar}
          onSucesso={aoRegistrar}
        />
        <RefeicaoSheet
          aberto={sheetAberto === 'refeicao'}
          onFechar={fechar}
          onSucesso={aoRegistrar}
        />
        <SintomasSheet
          aberto={sheetAberto === 'sintomas'}
          onFechar={fechar}
          onSucesso={aoRegistrar}
        />

        <footer className="mt-10 pb-4 text-center text-xs text-recorpo-muted">
          <p>Portal do paciente · beta</p>
          <p className="mt-1">
            App Android completo:{' '}
            <a
              href="https://play.google.com/apps/internaltest/4701303732446337597"
              className="text-brand-primaryLight hover:underline"
              target="_blank"
              rel="noopener"
            >
              instalar da Play Store
            </a>
          </p>
        </footer>
      </div>
    </main>
  );
}

function Header({
  nome,
  onLogout,
  onReload,
}: {
  nome: string;
  onLogout: () => void;
  onReload: () => void;
}) {
  const hora = new Date().getHours();
  const saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';
  return (
    <header>
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-recorpo-dim">
            Recorpo · assistente GLP-1
          </p>
          <h1 className="mt-1 text-2xl font-semibold tracking-tight text-recorpo-text sm:text-3xl">
            {saudacao}, {nome}
          </h1>
        </div>
        <div className="flex gap-2">
          <button
            onClick={onReload}
            className="rounded-lg border border-recorpo-border px-3 py-1.5 text-sm text-recorpo-dim transition hover:border-brand-primary hover:text-recorpo-text"
            aria-label="Atualizar dados"
          >
            ↻
          </button>
          <button
            onClick={onLogout}
            className="rounded-lg border border-recorpo-border px-3 py-1.5 text-sm text-recorpo-dim transition hover:border-brand-primary hover:text-recorpo-text"
          >
            Sair
          </button>
        </div>
      </div>
      <nav className="mt-4 flex gap-1 text-sm">
        <Link
          href="/app"
          className="rounded-lg bg-recorpo-surfaceHi px-3 py-1.5 text-recorpo-text"
        >
          Início
        </Link>
        <Link
          href="/app/historico"
          className="rounded-lg px-3 py-1.5 text-recorpo-dim hover:bg-recorpo-surfaceHi hover:text-recorpo-text"
        >
          Histórico
        </Link>
        <Link
          href="/app/perfil"
          className="rounded-lg px-3 py-1.5 text-recorpo-dim hover:bg-recorpo-surfaceHi hover:text-recorpo-text"
        >
          Perfil
        </Link>
      </nav>
    </header>
  );
}

function ResumoDoDia({ data }: { data: Record<string, unknown> }) {
  const linhas = (data.linhas as Array<{ eixo?: string; texto?: string }>) ?? [];
  if (linhas.length === 0) return null;
  return (
    <Card>
      <Label>Resumo do dia</Label>
      <ul className="mt-2 space-y-1.5 text-sm text-recorpo-text">
        {linhas.slice(0, 4).map((l, i) => (
          <li key={i} className="flex gap-2">
            <span className="text-brand-primaryLight" aria-hidden>
              •
            </span>
            <span>{l.texto ?? '—'}</span>
          </li>
        ))}
      </ul>
    </Card>
  );
}

function AcaoRapida({
  icone,
  titulo,
  hint,
  onClick,
  href,
  disabled = false,
}: {
  icone: string;
  titulo: string;
  hint?: string;
  onClick?: () => void;
  href?: string;
  disabled?: boolean;
}) {
  const className =
    'group flex flex-col items-center gap-1 rounded-xl border border-recorpo-border bg-recorpo-surface py-4 text-recorpo-text transition hover:border-brand-primary hover:bg-recorpo-surfaceHi disabled:cursor-not-allowed disabled:opacity-60';
  const conteudo = (
    <>
      <span className="text-2xl" aria-hidden>
        {icone}
      </span>
      <span className="text-sm font-medium">{titulo}</span>
      {hint && <span className="text-[10px] text-recorpo-muted">{hint}</span>}
    </>
  );
  if (href && !disabled) {
    return (
      <Link href={href} className={className} aria-label={titulo}>
        {conteudo}
      </Link>
    );
  }
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={className}
      aria-label={`Registrar ${titulo}`}
    >
      {conteudo}
    </button>
  );
}

function SkeletonCard({ tall = false }: { tall?: boolean }) {
  return (
    <div
      className={`rounded-2xl border border-recorpo-border bg-recorpo-surface p-5 ${
        tall ? 'h-32' : ''
      }`}
    >
      <Skeleton className="h-3 w-24" />
      <Skeleton className="mt-3 h-8 w-32" />
      <Skeleton className="mt-2 h-3 w-40" />
    </div>
  );
}
