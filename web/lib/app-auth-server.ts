/**
 * Server actions de autenticação do portal do paciente.
 *
 * SEGURANÇA — decisões:
 *   1. Refresh token vive em cookie httpOnly + SameSite=Strict + Secure.
 *      Nem JavaScript da página nem XSS de terceiros conseguem lê-lo.
 *   2. Access token NUNCA é persistido — só existe em memória (React
 *      state via AuthProvider). Se o user fecha a aba, precisa refresh.
 *   3. Refresh gera novo par (backend faz rotation + reuse detection).
 *      Se um refresh vazar de alguma forma, próximo uso invalida a
 *      família toda no backend e o user cai fora.
 *   4. Todas as chamadas passam pelo servidor (server actions) — o
 *      client nunca fala direto com o backend com o refresh, só o
 *      servidor Next fala.
 */
'use server';

import { cookies } from 'next/headers';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '';
const REFRESH_COOKIE = 'recorpo_refresh';
const COOKIE_MAX_AGE = 60 * 60 * 24 * 30; // 30 dias

export type Usuario = {
  id: string;
  email: string;
  nome: string | null;
  role: 'paciente' | 'profissional';
  dataNascimento?: string | null;
};

export type AuthResult =
  | { ok: true; accessToken: string; usuario: Usuario }
  | { ok: false; erro: string };

function setRefreshCookie(refreshToken: string) {
  // path='/' pra que server actions em qualquer rota do site consigam
  // ler o cookie. Antes usava path='/app' mas isso quebrava refresh
  // silencioso ao navegar entre rotas quando o next roteia via server
  // action em contexto diferente.
  //
  // Segurança preservada: cookie continua httpOnly (JS não lê) +
  // Secure (só HTTPS) + SameSite=Strict (não vaza pra outros sites).
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
  } catch (e) {
    return {
      ok: false,
      status: 0,
      erro: 'Não foi possível conectar. Verifique sua internet.',
    };
  }
}

export async function loginAction(
  email: string,
  senha: string
): Promise<AuthResult> {
  const r = await callBackend('/api/auth/login', { email, senha });
  if (!r.ok) return { ok: false, erro: r.erro };

  const { accessToken, refreshToken, usuario } = r.data;
  if (!accessToken || !refreshToken || !usuario) {
    return { ok: false, erro: 'Resposta inválida do servidor.' };
  }
  // Portal do paciente aceita só role=paciente. Se médico tentar
  // entrar aqui, redireciona ele pro /portal.
  if (usuario.role !== 'paciente') {
    return {
      ok: false,
      erro: 'Este acesso é para pacientes. Médicos entram em /portal.',
    };
  }
  setRefreshCookie(refreshToken);
  return { ok: true, accessToken, usuario };
}

export async function registrarAction(input: {
  nome: string;
  email: string;
  senha: string;
  dataNascimento: string;
}): Promise<AuthResult> {
  const r = await callBackend('/api/auth/registrar', input);
  if (!r.ok) return { ok: false, erro: r.erro };

  // O endpoint /registrar do backend só cria o usuário — depois
  // precisamos logar pra pegar tokens. Fluxo em 2 etapas.
  return loginAction(input.email, input.senha);
}

/**
 * Trocar refresh atual por novo par (backend rotaciona).
 * Chamado sempre que o access token expira ou no boot da SPA.
 * Retorna novo access token pra memória do client.
 */
export async function refreshAction(): Promise<AuthResult> {
  const refreshToken = cookies().get(REFRESH_COOKIE)?.value;
  if (!refreshToken) return { ok: false, erro: 'Sem sessão. Faça login.' };

  const r = await callBackend('/api/auth/refresh', { refreshToken });
  if (!r.ok) {
    // Se backend rejeitou (reuse detection, secret rotation etc.),
    // limpamos cookie pra não ficar em loop.
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

export async function logoutAction(): Promise<{ ok: true }> {
  const refreshToken = cookies().get(REFRESH_COOKIE)?.value;
  // Best-effort: avisa backend pra invalidar, mesmo se falhar limpamos
  // o cookie local (o próprio expire natural do refresh é fallback).
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
