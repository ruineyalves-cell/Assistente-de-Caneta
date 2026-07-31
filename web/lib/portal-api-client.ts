/**
 * Cliente HTTP do portal do profissional.
 *
 * Mesmo padrão do portal do paciente (app-api-client.ts):
 * access token em memória, refresh via server action httpOnly cookie.
 */

import { portalRefreshAction } from './portal-auth-server';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '';

export class ApiError extends Error {
  status: number;
  data: unknown;
  constructor(status: number, message: string, data: unknown = null) {
    super(message);
    this.status = status;
    this.data = data;
  }
}

type TokenGetter = () => string | null;
type TokenSetter = (novo: string) => void;
type LogoutCallback = () => void;

let getToken: TokenGetter = () => null;
let setToken: TokenSetter = () => {};
let onSessionLost: LogoutCallback = () => {};

export function registrarPortalTokenHooks(
  getter: TokenGetter,
  setter: TokenSetter,
  onLost: LogoutCallback
): void {
  getToken = getter;
  setToken = setter;
  onSessionLost = onLost;
}

async function tentarRefresh(): Promise<string | null> {
  const r = await portalRefreshAction();
  if (!r.ok) {
    onSessionLost();
    return null;
  }
  setToken(r.accessToken);
  return r.accessToken;
}

async function request<T>(
  path: string,
  init: RequestInit = {},
  jaTentouRefresh = false
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((init.headers as Record<string, string>) ?? {}),
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers,
    cache: 'no-store',
  });

  if (res.status === 401 && !jaTentouRefresh) {
    const novo = await tentarRefresh();
    if (novo) return request<T>(path, init, true);
    throw new ApiError(401, 'Sessão expirou. Faça login novamente.');
  }

  if (!res.ok) {
    let data: unknown = null;
    try {
      data = await res.json();
    } catch {
      /* corpo não é JSON */
    }
    const d = (data ?? {}) as { erro?: string; message?: string };
    const msg = d.erro || d.message || `Erro HTTP ${res.status}`;
    throw new ApiError(res.status, msg, data);
  }

  const ct = res.headers.get('content-type') ?? '';
  if (ct.includes('application/json')) return res.json() as Promise<T>;
  return (await res.text()) as unknown as T;
}

// ─────────────────────────────────────────────────────────────────────
// Endpoints do portal do profissional
// ─────────────────────────────────────────────────────────────────────

export type PacienteResumo = {
  id: string;
  nome: string | null;
  email: string;
  vinculadoEm?: string;
};

export type PacienteDetalhe = {
  perfil: {
    userId: string;
    medicacao: { id: number; nome: string; principioAtivo: string } | null;
    doseAtual: string | null;
    pesoInicialKg: number | null;
    alturaCm: number | null;
    metaPesoKg: number | null;
    eixoFarmacologico: string | null;
    identidadeGenero: string | null;
    ultimaDoseIso: string | null;
  } | null;
  logs: Array<{
    data: string;
    pesoKg: number | null;
    proteinaG: number | null;
    aguaMl: number | null;
    alimentos: string | null;
    doseAplicada: boolean | null;
    efeitosColaterais: string | null;
  }>;
  scores: Array<{ data: string; score: number }>;
  streak: number;
  aviso: string;
};

export async function listarPacientes(): Promise<{
  pacientes: PacienteResumo[];
}> {
  return request('/api/portal/pacientes');
}

export async function obterPaciente(id: string): Promise<PacienteDetalhe> {
  return request(`/api/portal/pacientes/${id}`);
}

export async function baixarRelatorioPdf(id: string): Promise<Blob> {
  const token = getToken();
  const headers: Record<string, string> = {};
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(
    `${API_BASE}/api/portal/pacientes/${id}/relatorio.pdf`,
    { headers, cache: 'no-store' }
  );

  if (res.status === 401) {
    const novo = await tentarRefresh();
    if (novo) return baixarRelatorioPdf(id);
    throw new ApiError(401, 'Sessão expirou. Faça login.');
  }

  if (!res.ok) {
    throw new ApiError(res.status, `Falha ao baixar PDF (${res.status})`);
  }
  return res.blob();
}
