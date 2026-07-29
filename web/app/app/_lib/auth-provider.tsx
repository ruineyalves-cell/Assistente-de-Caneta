'use client';

/**
 * AuthProvider — mantém o access token em memória (nunca em storage)
 * e expõe métodos pra login/logout/refresh. Componente Client.
 *
 * Sequência do boot:
 *   1. Provider monta com accessToken=null
 *   2. useEffect dispara refreshAction() — se cookie httpOnly existe,
 *      backend devolve novo par e o access vai pra memória
 *   3. Se refresh falhou, redireciona pra /app/login (unless na rota
 *      pública). Layout usa isso pra proteger rotas.
 */

import { useRouter, usePathname } from 'next/navigation';
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';

import {
  logoutAction,
  refreshAction,
  loginAction,
  registrarAction,
  type Usuario,
} from '@/lib/app-auth-server';
import { registrarTokenHooks } from '@/lib/app-api-client';

type EstadoAuth =
  | { status: 'carregando' }
  | { status: 'anonimo' }
  | { status: 'autenticado'; accessToken: string; usuario: Usuario };

type AuthContextValor = {
  estado: EstadoAuth;
  login: (email: string, senha: string) => Promise<{ ok: boolean; erro?: string }>;
  registrar: (input: {
    nome: string;
    email: string;
    senha: string;
    dataNascimento: string;
  }) => Promise<{ ok: boolean; erro?: string }>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValor | null>(null);

// Rotas públicas dentro de /app (não exigem sessão).
const ROTAS_PUBLICAS = new Set<string>([
  '/app/login',
  '/app/registro',
]);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [estado, setEstado] = useState<EstadoAuth>({ status: 'carregando' });

  // Registra hooks no cliente HTTP pra ele saber ler/renovar o token.
  useEffect(() => {
    registrarTokenHooks(
      () =>
        estado.status === 'autenticado' ? estado.accessToken : null,
      (novo) => {
        setEstado((prev) =>
          prev.status === 'autenticado'
            ? { ...prev, accessToken: novo }
            : prev
        );
      },
      () => {
        setEstado({ status: 'anonimo' });
        router.replace('/app/login');
      }
    );
  }, [estado, router]);

  // Boot: tenta refresh silencioso pra recuperar sessão.
  useEffect(() => {
    let cancelado = false;
    (async () => {
      const r = await refreshAction();
      if (cancelado) return;
      if (r.ok) {
        setEstado({
          status: 'autenticado',
          accessToken: r.accessToken,
          usuario: r.usuario,
        });
      } else {
        setEstado({ status: 'anonimo' });
      }
    })();
    return () => {
      cancelado = true;
    };
  }, []);

  // Gate de rotas: se anônimo e tentando rota protegida, redireciona
  // pro login. Se autenticado e em rota pública, manda pro dashboard.
  useEffect(() => {
    if (estado.status === 'carregando') return;
    const publica = ROTAS_PUBLICAS.has(pathname);
    if (estado.status === 'anonimo' && !publica) {
      router.replace('/app/login');
    } else if (estado.status === 'autenticado' && publica) {
      router.replace('/app');
    }
  }, [estado.status, pathname, router]);

  const login = useCallback(
    async (email: string, senha: string) => {
      const r = await loginAction(email, senha);
      if (!r.ok) return { ok: false, erro: r.erro };
      setEstado({
        status: 'autenticado',
        accessToken: r.accessToken,
        usuario: r.usuario,
      });
      return { ok: true };
    },
    []
  );

  const registrar = useCallback(
    async (input: {
      nome: string;
      email: string;
      senha: string;
      dataNascimento: string;
    }) => {
      const r = await registrarAction(input);
      if (!r.ok) return { ok: false, erro: r.erro };
      setEstado({
        status: 'autenticado',
        accessToken: r.accessToken,
        usuario: r.usuario,
      });
      return { ok: true };
    },
    []
  );

  const logout = useCallback(async () => {
    await logoutAction();
    setEstado({ status: 'anonimo' });
    router.replace('/app/login');
  }, [router]);

  const valor = useMemo(
    () => ({ estado, login, registrar, logout }),
    [estado, login, registrar, logout]
  );

  return <AuthContext.Provider value={valor}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth só funciona dentro do AuthProvider');
  return ctx;
}
