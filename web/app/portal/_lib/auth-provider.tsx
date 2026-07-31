'use client';

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
  portalLoginAction,
  portalLogoutAction,
  portalRefreshAction,
  type Usuario,
} from '@/lib/portal-auth-server';
import { registrarPortalTokenHooks } from '@/lib/portal-api-client';

type EstadoAuth =
  | { status: 'carregando' }
  | { status: 'anonimo' }
  | { status: 'autenticado'; accessToken: string; usuario: Usuario };

type PortalAuthContextValor = {
  estado: EstadoAuth;
  login: (email: string, senha: string) => Promise<{ ok: boolean; erro?: string }>;
  logout: () => Promise<void>;
};

const PortalAuthContext = createContext<PortalAuthContextValor | null>(null);

const ROTAS_PUBLICAS = new Set<string>(['/portal/login']);

export function PortalAuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [estado, setEstado] = useState<EstadoAuth>({ status: 'carregando' });

  useEffect(() => {
    registrarPortalTokenHooks(
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
        router.replace('/portal/login');
      }
    );
  }, [estado, router]);

  useEffect(() => {
    let cancelado = false;
    (async () => {
      const r = await portalRefreshAction();
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

  useEffect(() => {
    if (estado.status === 'carregando') return;
    const publica = ROTAS_PUBLICAS.has(pathname);
    if (estado.status === 'anonimo' && !publica) {
      router.replace('/portal/login');
    } else if (estado.status === 'autenticado' && publica) {
      router.replace('/portal/pacientes');
    }
  }, [estado.status, pathname, router]);

  const login = useCallback(
    async (email: string, senha: string) => {
      const r = await portalLoginAction(email, senha);
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
    await portalLogoutAction();
    setEstado({ status: 'anonimo' });
    router.replace('/portal/login');
  }, [router]);

  const valor = useMemo(
    () => ({ estado, login, logout }),
    [estado, login, logout]
  );

  return (
    <PortalAuthContext.Provider value={valor}>
      {children}
    </PortalAuthContext.Provider>
  );
}

export function usePortalAuth() {
  const ctx = useContext(PortalAuthContext);
  if (!ctx) throw new Error('usePortalAuth só funciona dentro do PortalAuthProvider');
  return ctx;
}
