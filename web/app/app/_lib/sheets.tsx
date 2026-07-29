'use client';

/**
 * Sheets de registro do portal do paciente. Cada um posta em
 * POST /api/logs (mesma superfície do app Android). Após sucesso,
 * chama `onSucesso` que o dashboard usa pra recarregar dados.
 */

import { useState } from 'react';

import { api, ApiError } from '@/lib/app-api-client';
import { ActionSheet } from './action-sheet';

type Props = {
  aberto: boolean;
  onFechar: () => void;
  onSucesso: () => void;
};

// Mesmos incrementos da versão Android (WaterQuickSheet).
const INCREMENTOS_AGUA = [250, 500, 750, 1000];

/** Converte Date pro formato YYYY-MM-DD que o backend Zod aceita. */
function dataISO(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
}

async function postar(dados: {
  data: Date;
  pesoKg?: number;
  proteinaG?: number;
  aguaMl?: number;
  alimentos?: string;
  doseAplicada?: boolean;
  efeitos?: string;
}): Promise<{ ok: true } | { ok: false; erro: string }> {
  try {
    // Backend espera:
    //   - data: string YYYY-MM-DD (regex estrita, ISO cheio quebra)
    //   - efeitos (NÃO efeitosColaterais): string JSON
    //   - campos numéricos nunca undefined; usar null explícito
    const payload: Record<string, unknown> = {
      data: dataISO(dados.data),
      doseAplicada: dados.doseAplicada ?? false,
    };
    if (dados.pesoKg != null) payload.pesoKg = dados.pesoKg;
    if (dados.proteinaG != null) payload.proteinaG = dados.proteinaG;
    if (dados.aguaMl != null) payload.aguaMl = dados.aguaMl;
    if (dados.alimentos) payload.alimentos = dados.alimentos;
    if (dados.efeitos) payload.efeitos = dados.efeitos;
    await api.registrarLog(payload as any);
    return { ok: true };
  } catch (e) {
    return {
      ok: false,
      erro:
        e instanceof ApiError
          ? e.message
          : (e as Error).message ?? 'Erro desconhecido',
    };
  }
}

function BotaoSalvar({
  loading,
  disabled,
  label = 'Salvar',
}: {
  loading: boolean;
  disabled?: boolean;
  label?: string;
}) {
  return (
    <button
      type="submit"
      disabled={loading || disabled}
      className="mt-4 w-full rounded-lg bg-brand-primary py-3 font-medium text-white transition hover:bg-brand-primaryDark disabled:cursor-not-allowed disabled:opacity-50"
    >
      {loading ? 'Salvando…' : label}
    </button>
  );
}

function Erro({ msg }: { msg: string | null }) {
  if (!msg) return null;
  return (
    <div className="mt-3 rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/10 px-3 py-2 text-sm text-eixo-sintomas">
      {msg}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Dose
// ─────────────────────────────────────────────────────────────────────
export function DoseSheet({ aberto, onFechar, onSucesso }: Props) {
  const [loading, setLoading] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  async function salvar(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setErro(null);
    const r = await postar({ data: new Date(), doseAplicada: true });
    setLoading(false);
    if (r.ok) {
      onSucesso();
      onFechar();
    } else {
      setErro(r.erro);
    }
  }

  return (
    <ActionSheet aberto={aberto} onFechar={onFechar} titulo="Registrar dose">
      <form onSubmit={salvar}>
        <p className="text-sm text-recorpo-dim">
          Marca a aplicação da dose de hoje. Você pode editar depois no
          histórico.
        </p>
        <Erro msg={erro} />
        <BotaoSalvar loading={loading} label="Confirmar dose de hoje" />
      </form>
    </ActionSheet>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Água
// ─────────────────────────────────────────────────────────────────────
export function AguaSheet({ aberto, onFechar, onSucesso }: Props) {
  const [ml, setMl] = useState(500);
  const [loading, setLoading] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  async function salvarValor(valor: number) {
    setMl(valor);
    setLoading(true);
    setErro(null);
    const r = await postar({ data: new Date(), aguaMl: valor });
    setLoading(false);
    if (r.ok) {
      onSucesso();
      onFechar();
    } else {
      setErro(r.erro);
    }
  }

  return (
    <ActionSheet aberto={aberto} onFechar={onFechar} titulo="Registrar hidratação">
      <p className="text-sm text-recorpo-dim">Quanto você bebeu?</p>
      <div className="mt-4 grid grid-cols-2 gap-3">
        {INCREMENTOS_AGUA.map((v) => (
          <button
            key={v}
            type="button"
            onClick={() => salvarValor(v)}
            disabled={loading}
            className="rounded-xl border border-recorpo-border bg-recorpo-bg py-4 text-center transition hover:border-eixo-agua hover:bg-eixo-agua/10 disabled:cursor-not-allowed disabled:opacity-50"
          >
            <span className="block text-2xl">💧</span>
            <span className="mt-1 block text-sm font-semibold text-recorpo-text">
              +{v >= 1000 ? `${(v / 1000).toFixed(1)}L` : `${v} ml`}
            </span>
          </button>
        ))}
      </div>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (ml > 0) salvarValor(ml);
        }}
        className="mt-4"
      >
        <label className="block">
          <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
            Ou digite o volume em ml
          </span>
          <input
            type="number"
            min={50}
            max={5000}
            value={ml}
            onChange={(e) => setMl(Number(e.target.value))}
            className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-eixo-agua focus:ring-2 focus:ring-eixo-agua/30"
          />
        </label>
        <Erro msg={erro} />
        <BotaoSalvar loading={loading} disabled={ml <= 0} label="Salvar" />
      </form>
    </ActionSheet>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Peso
// ─────────────────────────────────────────────────────────────────────
export function PesoSheet({ aberto, onFechar, onSucesso }: Props) {
  const [peso, setPeso] = useState('');
  const [loading, setLoading] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  const pesoNum = Number(peso.replace(',', '.'));
  const valido = Number.isFinite(pesoNum) && pesoNum >= 20 && pesoNum <= 400;

  async function salvar(e: React.FormEvent) {
    e.preventDefault();
    if (!valido) return;
    setLoading(true);
    setErro(null);
    const r = await postar({
      data: new Date(),
      pesoKg: pesoNum,
      alimentos: `Peso: ${pesoNum.toFixed(1)} kg`,
    });
    setLoading(false);
    if (r.ok) {
      onSucesso();
      onFechar();
    } else {
      setErro(r.erro);
    }
  }

  return (
    <ActionSheet aberto={aberto} onFechar={onFechar} titulo="Registrar peso">
      <form onSubmit={salvar}>
        <label className="block">
          <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
            Peso (kg)
          </span>
          <input
            type="text"
            inputMode="decimal"
            value={peso}
            onChange={(e) => setPeso(e.target.value)}
            placeholder="Ex: 78,5"
            className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-eixo-peso focus:ring-2 focus:ring-eixo-peso/30"
          />
        </label>
        {peso && !valido && (
          <p className="mt-1 text-xs text-eixo-sintomas">
            Peso precisa estar entre 20 e 400 kg.
          </p>
        )}
        <Erro msg={erro} />
        <BotaoSalvar loading={loading} disabled={!valido} label="Salvar peso" />
      </form>
    </ActionSheet>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Refeição (manual — sem scanner IA nesta fase)
// ─────────────────────────────────────────────────────────────────────
export function RefeicaoSheet({ aberto, onFechar, onSucesso }: Props) {
  const [descricao, setDescricao] = useState('');
  const [proteina, setProteina] = useState('');
  const [loading, setLoading] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  const proteinaNum = proteina ? Number(proteina.replace(',', '.')) : null;
  const valido = descricao.trim().length >= 2;

  async function salvar(e: React.FormEvent) {
    e.preventDefault();
    if (!valido) return;
    setLoading(true);
    setErro(null);
    const r = await postar({
      data: new Date(),
      alimentos: descricao.trim(),
      proteinaG:
        proteinaNum != null && Number.isFinite(proteinaNum) && proteinaNum > 0
          ? Math.round(proteinaNum)
          : undefined,
    });
    setLoading(false);
    if (r.ok) {
      onSucesso();
      onFechar();
    } else {
      setErro(r.erro);
    }
  }

  return (
    <ActionSheet aberto={aberto} onFechar={onFechar} titulo="Registrar refeição">
      <form onSubmit={salvar} className="space-y-3">
        <label className="block">
          <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
            O que você comeu
          </span>
          <textarea
            value={descricao}
            onChange={(e) => setDescricao(e.target.value)}
            rows={3}
            placeholder="Ex: Frango grelhado com salada e arroz integral"
            className="w-full resize-none rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-eixo-refeicao focus:ring-2 focus:ring-eixo-refeicao/30"
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-recorpo-dim">
            Proteína estimada (g, opcional)
          </span>
          <input
            type="text"
            inputMode="decimal"
            value={proteina}
            onChange={(e) => setProteina(e.target.value)}
            placeholder="Ex: 30"
            className="w-full rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2.5 text-recorpo-text outline-none focus:border-eixo-refeicao focus:ring-2 focus:ring-eixo-refeicao/30"
          />
        </label>
        <Erro msg={erro} />
        <BotaoSalvar loading={loading} disabled={!valido} label="Salvar refeição" />
        <p className="text-center text-xs text-recorpo-muted">
          Scanner IA de refeição vem na Fase 2 (usa câmera).
        </p>
      </form>
    </ActionSheet>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Sintomas
// ─────────────────────────────────────────────────────────────────────
const SINTOMAS_COMUNS = [
  'Náusea',
  'Vômito',
  'Diarreia',
  'Constipação',
  'Refluxo',
  'Dor abdominal',
  'Fadiga',
  'Dor de cabeça',
  'Tontura',
  'Palpitação',
];

type Intensidade = 'leve' | 'moderada' | 'intensa';

export function SintomasSheet({ aberto, onFechar, onSucesso }: Props) {
  const [selecionados, setSelecionados] = useState<
    Record<string, Intensidade | undefined>
  >({});
  const [loading, setLoading] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  function toggle(nome: string, intensidade: Intensidade) {
    setSelecionados((prev) => {
      const atual = prev[nome];
      // Clicar de novo na mesma intensidade → desmarca.
      if (atual === intensidade) {
        const { [nome]: _, ...resto } = prev;
        return resto;
      }
      return { ...prev, [nome]: intensidade };
    });
  }

  const sintomasArr = Object.entries(selecionados)
    .filter(([, i]) => i)
    .map(([nome, intensidade]) => ({ nome, intensidade }));
  const valido = sintomasArr.length > 0;

  async function salvar(e: React.FormEvent) {
    e.preventDefault();
    if (!valido) return;
    setLoading(true);
    setErro(null);
    // Formato JSON esperado pelo backend (mesmo do app):
    // { sintomas: [{ nome, intensidade }] }
    const efeitos = JSON.stringify({ sintomas: sintomasArr });
    const r = await postar({
      data: new Date(),
      efeitos,
    });
    setLoading(false);
    if (r.ok) {
      onSucesso();
      onFechar();
    } else {
      setErro(r.erro);
    }
  }

  const intensidadeCores: Record<Intensidade, string> = {
    leve: 'bg-brand-primary/20 border-brand-primary text-brand-primaryLight',
    moderada: 'bg-eixo-streak/20 border-eixo-streak text-eixo-streak',
    intensa: 'bg-eixo-sintomas/20 border-eixo-sintomas text-eixo-sintomas',
  };

  return (
    <ActionSheet aberto={aberto} onFechar={onFechar} titulo="Registrar sintomas">
      <form onSubmit={salvar}>
        <p className="mb-3 text-sm text-recorpo-dim">
          Toque na intensidade dos sintomas que você sentiu hoje.
        </p>
        <div className="max-h-72 space-y-2 overflow-y-auto pr-1">
          {SINTOMAS_COMUNS.map((sintoma) => (
            <div
              key={sintoma}
              className="flex items-center justify-between gap-2 rounded-lg border border-recorpo-border bg-recorpo-bg px-3 py-2"
            >
              <span className="text-sm text-recorpo-text">{sintoma}</span>
              <div className="flex gap-1">
                {(['leve', 'moderada', 'intensa'] as Intensidade[]).map(
                  (i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => toggle(sintoma, i)}
                      className={`rounded-md border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide transition ${
                        selecionados[sintoma] === i
                          ? intensidadeCores[i]
                          : 'border-recorpo-border text-recorpo-muted hover:border-recorpo-dim'
                      }`}
                    >
                      {i[0]}
                    </button>
                  )
                )}
              </div>
            </div>
          ))}
        </div>
        <Erro msg={erro} />
        <BotaoSalvar
          loading={loading}
          disabled={!valido}
          label={
            valido
              ? `Salvar ${sintomasArr.length} sintoma${sintomasArr.length > 1 ? 's' : ''}`
              : 'Selecione ao menos 1'
          }
        />
      </form>
    </ActionSheet>
  );
}
