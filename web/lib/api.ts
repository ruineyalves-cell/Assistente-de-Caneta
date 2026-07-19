/**
 * Cliente HTTP mínimo do backend Recorpo. Usa o mesmo endpoint do app
 * Flutter (variável NEXT_PUBLIC_API_BASE). O token JWT é guardado
 * em localStorage sob a chave `recorpo_pro_token` — quando o cookie
 * de portal for adicionado no backend, migramos para httpOnly.
 */

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '';
const TOKEN_KEY = 'recorpo_pro_token';

export class ApiError extends Error {
  status: number;
  data: unknown;
  constructor(status: number, message: string, data: unknown = null) {
    super(message);
    this.status = status;
    this.data = data;
  }
}

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken(): void {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(TOKEN_KEY);
}

export function isAutenticado(): boolean {
  return getToken() !== null;
}

async function request<T>(
  path: string,
  init: RequestInit = {}
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((init.headers as Record<string, string>) ?? {}),
  };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers,
  });
  if (!res.ok) {
    let data: unknown = null;
    try {
      data = await res.json();
    } catch {
      /* corpo não é JSON */
    }
    const dataObj = (data ?? {}) as { erro?: string; message?: string };
    const msg = dataObj.erro ?? dataObj.message ?? `Erro ${res.status}`;
    throw new ApiError(res.status, msg, data);
  }
  const ct = res.headers.get('content-type') ?? '';
  if (ct.includes('application/json')) {
    return res.json() as Promise<T>;
  }
  return (await res.text()) as unknown as T;
}

// ─────────────────────────────────────────────────────────────────────
// Auth (usa /api/auth/login existente do backend)
// ─────────────────────────────────────────────────────────────────────
export type LoginResposta = {
  usuario: {
    id: string;
    email: string;
    nome: string | null;
    role: 'paciente' | 'profissional' | 'admin';
  };
  accessToken: string;
  refreshToken?: string;
};

export async function login(
  email: string,
  senha: string
): Promise<LoginResposta> {
  const resposta = await request<LoginResposta>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, senha }),
  });
  setToken(resposta.accessToken);
  return resposta;
}

// ─────────────────────────────────────────────────────────────────────
// Portal do profissional
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

/** Baixa o PDF do relatório do paciente como Blob para download. */
export async function baixarRelatorioPdf(id: string): Promise<Blob> {
  const token = getToken();
  const res = await fetch(
    `${API_BASE}/api/portal/pacientes/${id}/relatorio.pdf`,
    {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }
  );
  if (!res.ok) {
    throw new ApiError(res.status, `Falha ao baixar PDF (${res.status})`);
  }
  return res.blob();
}
