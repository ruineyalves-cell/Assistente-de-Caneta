'use client';

/**
 * Hook `useDashboardData` — busca dashboard + resumo diário + alertas
 * + logs recentes em paralelo. Cada bloco tem loading/erro próprio pra
 * UI degradar graciosamente se um endpoint falha.
 *
 * Cache-first não implementado aqui (browser + Next já cacheia HTTP
 * quando o backend permite; dashboard.dashboard tem Cache-Control nulo
 * intencionalmente pra sempre ser fresh).
 */

import { useCallback, useEffect, useState } from 'react';

import { api, type DailyLog, type DashboardResp } from '@/lib/app-api-client';

type Estado<T> =
  | { status: 'loading' }
  | { status: 'ok'; data: T }
  | { status: 'error'; erro: string };

export type DashboardData = {
  dashboard: Estado<DashboardResp>;
  resumo: Estado<Record<string, unknown>>;
  alertas: Estado<Array<Record<string, unknown>>>;
  logsHoje: Estado<DailyLog[]>;
  reload: () => void;
};

/** Retorna todos logs cujo `data` for igual a hoje (YYYY-MM-DD local). */
function apenasHoje(logs: DailyLog[]): DailyLog[] {
  const hoje = new Date();
  const y = hoje.getFullYear();
  const m = String(hoje.getMonth() + 1).padStart(2, '0');
  const d = String(hoje.getDate()).padStart(2, '0');
  const chave = `${y}-${m}-${d}`;
  return logs.filter((l) => l.data.startsWith(chave));
}

export function useDashboardData(accessToken: string | null): DashboardData {
  const [dashboard, setDashboard] = useState<Estado<DashboardResp>>({
    status: 'loading',
  });
  const [resumo, setResumo] = useState<Estado<Record<string, unknown>>>({
    status: 'loading',
  });
  const [alertas, setAlertas] = useState<
    Estado<Array<Record<string, unknown>>>
  >({ status: 'loading' });
  const [logsHoje, setLogsHoje] = useState<Estado<DailyLog[]>>({
    status: 'loading',
  });
  const [nonce, setNonce] = useState(0);

  const reload = useCallback(() => setNonce((n) => n + 1), []);

  useEffect(() => {
    if (!accessToken) return;
    let cancelado = false;

    // Fetch em paralelo — o mais lento não bloqueia os outros.
    api
      .dashboard()
      .then((data) => !cancelado && setDashboard({ status: 'ok', data }))
      .catch((e) =>
        !cancelado &&
        setDashboard({ status: 'error', erro: e.message ?? 'Falhou' })
      );

    api
      .resumoDiario()
      .then((data) => !cancelado && setResumo({ status: 'ok', data }))
      .catch((e) =>
        !cancelado && setResumo({ status: 'error', erro: e.message ?? 'Falhou' })
      );

    api
      .alertas()
      .then((data) => !cancelado && setAlertas({ status: 'ok', data }))
      .catch((e) =>
        !cancelado &&
        setAlertas({ status: 'error', erro: e.message ?? 'Falhou' })
      );

    api
      .listarLogs()
      .then(
        (data) =>
          !cancelado && setLogsHoje({ status: 'ok', data: apenasHoje(data) })
      )
      .catch((e) =>
        !cancelado &&
        setLogsHoje({ status: 'error', erro: e.message ?? 'Falhou' })
      );

    return () => {
      cancelado = true;
    };
  }, [accessToken, nonce]);

  return { dashboard, resumo, alertas, logsHoje, reload };
}
