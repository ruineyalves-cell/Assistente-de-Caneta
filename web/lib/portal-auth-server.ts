'use server';

import { cookies } from 'next/headers';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '';
const REFRESH_COOKIE = 'recorpo_pro_refresh';
const COOKIE_MAX_AGE = 60 * 60 * 24 * 30; // 30 dias

export type Usuario = {
  id: string;
  email: string;
  nome: string | null;
  role: 'paciente' | 'profissional';
};

export type AuthResult =
  | { ok: true; accessToken: string; usuario: Usuario }
  | { ok: false; erro: string };

function setRefreshCookie(refreshToken: string) {
  cookies().set(REFRESH_COOKIE, refreshToken, {
    httpOnly: true,
    secure: true,
    sameSite: 'strict',
    path: '/',
    maxAge: COOKIE_MAX_AGE,
  });
}

function clearRefreshCookie() {
  cookies().delete(REFRESH_COOKIE);
}

async function callBackend(
  path: string,
  body: Record<string, unknown>
): Promise<{ ok: true; data: any } | { ok: false; status: number; erro: string }> {
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      cache: 'no-store',
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      return {
        ok: false,
        status: res.status,
        erro: data?.erro || data?.message || `Erro HTTP ${res.status}`,
      };
    }
    return { ok: true, data };
  } catch {
    return {
      ok: false,
      status: 0,
      erro: 'Não foi possível conectar. Verifique sua internet.',
    };
  }
}

export async function portalLoginAction(
  email: string,
  senha: string
): Promise<AuthResult> {
  const r = await callBackend('/api/auth/login', { email, senha });
  if (!r.ok) return { ok: false, erro: r.erro };

  const { accessToken, refreshToken, usuario } = r.data;
  if (!accessToken || !refreshToken || !usuario) {
    return { ok: false, erro: 'Resposta inválida do servidor.' };
  }
  if (usuario.role !== 'profissional') {
    return {
      ok: false,
      erro: 'Este acesso é exclusivo de profissionais. Pacientes usam /app.',
    };
  }
  setRefreshCookie(refreshToken);
  return { ok: true, accessToken, usuario };
}

export async function portalRefreshAction(): Promise<AuthResult> {
  const refreshToken = cookies().get(REFRESH_COOKIE)?.value;
  if (!refreshToken) return { ok: false, erro: 'Sem sessão. Faça login.' };

  const r = await callBackend('/api/auth/refresh', { refreshToken });
  if (!r.ok) {
    if (r.status === 401 || r.status === 403) clearRefreshCookie();
    return { ok: false, erro: r.erro };
  }

  const { accessToken, refreshToken: novoRefresh, usuario } = r.data;
  if (!accessToken || !novoRefresh || !usuario) {
    return { ok: false, erro: 'Resposta inválida do servidor.' };
  }
  setRefreshCookie(novoRefresh);
  return { ok: true, accessToken, usuario };
}

export async function portalLogoutAction(): Promise<{ ok: true }> {
  const refreshToken = cookies().get(REFRESH_COOKIE)?.value;
  if (refreshToken) {
    try {
      await fetch(`${API_BASE}/api/auth/logout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${refreshToken}`,
        },
        body: JSON.stringify({ refreshToken }),
        cache: 'no-store',
      });
    } catch {
      /* silencioso */
    }
  }
  clearRefreshCookie();
  return { ok: true };
}
