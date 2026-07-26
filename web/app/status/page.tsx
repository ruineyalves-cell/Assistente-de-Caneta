import type { Metadata } from 'next';
import LegalLayout from '@/components/legal-layout';

/**
 * /status — Página pública de health check do backend Recorpo (Lote I2).
 *
 * Server component: o fetch acontece no build/request do Next, o cliente
 * recebe HTML pronto. Nenhum secret exposto no browser.
 *
 * Cache: revalidate=30s. Evita bombardear /health do Render em cada
 * pageview mas mostra estado praticamente em tempo real.
 */

export const metadata: Metadata = {
  title: 'Status do sistema',
  description:
    'Estado atual dos serviços do Recorpo — backend, banco de dados e integrações.',
};

// ISR: página é regenerada no máximo a cada 30s.
export const revalidate = 30;

const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE ||
  'https://assistente-caneta-backend-tkl7.onrender.com';

type Health = {
  ok: boolean;
  latencyMs: number | null;
  servico?: string;
  versao?: string;
  erro?: string;
  timestamp: string;
};

async function pingHealth(): Promise<Health> {
  const started = Date.now();
  const timestamp = new Date().toISOString();
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    const res = await fetch(`${API_BASE}/health`, {
      signal: controller.signal,
      // Server-side fetch — sem cache do Next pra não mascarar downtime.
      cache: 'no-store',
    });
    clearTimeout(timeout);
    const latencyMs = Date.now() - started;
    if (!res.ok) {
      return { ok: false, latencyMs, erro: `HTTP ${res.status}`, timestamp };
    }
    const body = (await res.json()) as { ok?: boolean; servico?: string; versao?: string };
    return {
      ok: body.ok === true,
      latencyMs,
      servico: body.servico,
      versao: body.versao,
      timestamp,
    };
  } catch (err) {
    const latencyMs = Date.now() - started;
    const msg = err instanceof Error ? err.message : String(err);
    return { ok: false, latencyMs, erro: msg, timestamp };
  }
}

function Pill({ ok }: { ok: boolean }) {
  const cor = ok ? 'bg-emerald-500/20 text-emerald-300 border-emerald-400/30' : 'bg-red-500/20 text-red-300 border-red-400/30';
  const label = ok ? 'Operacional' : 'Fora do ar';
  return (
    <span
      className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold ${cor}`}
      aria-live="polite"
    >
      <span className={`h-2 w-2 rounded-full ${ok ? 'bg-emerald-400' : 'bg-red-400'}`} />
      {label}
    </span>
  );
}

function Linha({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between border-t border-white/5 py-3 text-sm">
      <span className="text-recorpo-dim">{label}</span>
      <span className="text-recorpo-text font-mono">{value}</span>
    </div>
  );
}

export default async function StatusPage() {
  const backend = await pingHealth();

  return (
    <LegalLayout titulo="Status do sistema">
      <section className="mt-8 space-y-6">
        {/* Backend API */}
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-lg font-semibold text-recorpo-text">API Recorpo</h2>
              <p className="text-xs text-recorpo-dim mt-1">
                Backend Node.js hospedado no Render (Ohio, EUA).
              </p>
            </div>
            <Pill ok={backend.ok} />
          </div>
          <div>
            <Linha
              label="Latência"
              value={backend.latencyMs != null ? `${backend.latencyMs} ms` : '—'}
            />
            <Linha label="Serviço" value={backend.servico ?? '—'} />
            <Linha label="Versão" value={backend.versao ?? '—'} />
            {backend.erro && (
              <Linha label="Erro" value={backend.erro.slice(0, 60)} />
            )}
            <Linha
              label="Verificado em"
              value={new Date(backend.timestamp).toLocaleString('pt-BR', {
                dateStyle: 'short',
                timeStyle: 'medium',
              })}
            />
          </div>
        </div>

        {/* Aviso ISR */}
        <p className="text-xs text-recorpo-dim text-center">
          Esta página revalida a cada 30 segundos. Recarregue para forçar novo check.
        </p>

        {/* Se estiver fora, orientação */}
        {!backend.ok && (
          <div className="rounded-2xl border border-red-500/30 bg-red-500/5 p-6 text-sm text-recorpo-text">
            <h3 className="font-semibold mb-2">O que fazer?</h3>
            <ul className="list-disc list-inside space-y-1 text-recorpo-dim">
              <li>Se estiver usando o app agora, tente daqui alguns segundos.</li>
              <li>Se persistir, escreva para <a className="text-brand-primaryLight underline" href="mailto:recorpoapp@gmail.com">recorpoapp@gmail.com</a>.</li>
              <li>Seus dados locais (últimas 24h) continuam salvos no seu aparelho.</li>
            </ul>
          </div>
        )}
      </section>
    </LegalLayout>
  );
}
