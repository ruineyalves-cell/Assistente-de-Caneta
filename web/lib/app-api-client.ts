/**
 * Cliente HTTP autenticado do portal do paciente.
 *
 * Chama endpoints /api/* do backend usando o access token que vive
 * em memória (via AuthProvider). Se receber 401, dispara refresh via
 * server action e reenvia a request 1×. Se ainda falhar, deixa a
 * exception subir — o AuthProvider pega e faz logout gracioso.
 *
 * Não usa localStorage/sessionStorage — só o accessToken em memória.
 * Refresh é lido via cookie httpOnly na server action.
 */

import { refreshAction } from './app-auth-server';

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

// Callback do AuthProvider pra receber novo access token após refresh.
// O provider registra isso no boot; o client usa quando faz retry.
type TokenGetter = () => string | null;
type TokenSetter = (novo: string) => void;
type LogoutCallback = () => void;

let getToken: TokenGetter = () => null;
let setToken: TokenSetter = () => {};
let onSessionLost: LogoutCallback = () => {};

export function registrarTokenHooks(
  getter: TokenGetter,
  setter: TokenSetter,
  onLost: LogoutCallback
): void {
  getToken = getter;
  setToken = setter;
  onSessionLost = onLost;
}

async function tentarRefresh(): Promise<string | null> {
  const r = await refreshAction();
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

  // 401 → tenta refresh 1× e reenvia
  if (res.status === 401 && !jaTentouRefresh) {
    const novo = await tentarRefresh();
    if (novo) return request<T>(path, init, true);
    // refresh falhou — onSessionLost já foi chamado
    throw new ApiError(401, 'Sessão expirou. Faça login novamente.');
  }

  if (!res.ok) {
    let data: unknown = null;
    try {
      data = await res.json();
    } catch {
      /* corpo não é JSON — ex: HTML de erro do proxy */
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
// Endpoints usados pelo portal do paciente. Mesma superfície do app.
// ─────────────────────────────────────────────────────────────────────

export type DailyLog = {
  id: string;
  data: string;
  pesoKg: number | null;
  proteinaG: number | null;
  aguaMl: number | null;
  alimentos: string | null;
  doseAplicada: boolean;
  efeitosColaterais: string | null;
};

export type DashboardResp = {
  streak: number;
  scores28dias: Array<{ data: string; score: number }>;
};

export const api = {
  // Perfil
  obterPerfil: () => request<Record<string, unknown>>('/api/pacientes/perfil'),
  salvarPerfil: (dados: Record<string, unknown>) =>
    request<Record<string, unknown>>('/api/pacientes/perfil', {
      method: 'PUT',
      body: JSON.stringify(dados),
    }),

  // Dashboard e resumos
  dashboard: () => request<DashboardResp>('/api/logs/dashboard'),
  resumoDiario: () =>
    request<Record<string, unknown>>('/api/pacientes/resumo-diario'),
  alertas: () =>
    request<Array<Record<string, unknown>>>('/api/pacientes/alertas'),

  // Logs
  listarLogs: () => request<DailyLog[]>('/api/logs'),
  registrarLog: (log: Partial<DailyLog>) =>
    request<{ score?: number }>('/api/logs', {
      method: 'POST',
      body: JSON.stringify(log),
    }),

  // LGPD
  registrarConsentimento: (tipo: string) =>
    request<{ ok: true }>('/api/lgpd/consentimento', {
      method: 'POST',
      body: JSON.stringify({ tipo, aceito: true }),
    }),
  listarConsentimentos: () =>
    request<Array<{ tipo: string; aceito: boolean }>>(
      '/api/lgpd/consentimentos'
    ),
};
