import type { MetadataRoute } from 'next';

/**
 * PWA manifest. start_url aponta pra /app pra que "Adicionar à tela
 * inicial" já leve o user pro portal (o site marketing é acessado só
 * uma vez, o app diário é o que importa).
 *
 * scope=/ deixa o PWA controlar o site inteiro (senão o botão de
 * instalação some ao navegar pra fora do escopo).
 *
 * shortcuts aparecem como atalhos ao segurar o ícone no Android (long-
 * press) — permite ir direto pro histórico ou pro perfil sem passar
 * pelo dashboard.
 */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Recorpo — Assistente de Caneta GLP-1',
    short_name: 'Recorpo',
    description:
      'Registre suas aplicações, acompanhe sua evolução e leve um relatório claro para o médico.',
    start_url: '/app',
    scope: '/',
    display: 'standalone',
    background_color: '#0B1220',
    theme_color: '#0B1220',
    lang: 'pt-BR',
    orientation: 'portrait',
    categories: ['medical', 'health', 'lifestyle'],
    icons: [
      { src: '/icon', sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: '/icon', sizes: '512x512', type: 'image/png', purpose: 'any' },
      { src: '/icon', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
    shortcuts: [
      {
        name: 'Registrar dose',
        short_name: 'Dose',
        url: '/app?acao=dose',
        icons: [{ src: '/icon', sizes: '192x192' }],
      },
      {
        name: 'Histórico',
        short_name: 'Histórico',
        url: '/app/historico',
        icons: [{ src: '/icon', sizes: '192x192' }],
      },
      {
        name: 'Perfil',
        short_name: 'Perfil',
        url: '/app/perfil',
        icons: [{ src: '/icon', sizes: '192x192' }],
      },
    ],
  };
}
