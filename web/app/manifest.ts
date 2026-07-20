import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Recorpo — Assistente de Caneta GLP-1',
    short_name: 'Recorpo',
    description:
      'Registre suas aplicações, acompanhe sua evolução e leve um relatório claro para o médico.',
    start_url: '/',
    display: 'standalone',
    background_color: '#0B111A',
    theme_color: '#2B6CB0',
    lang: 'pt-BR',
    orientation: 'portrait',
    icons: [
      { src: '/icon', sizes: '192x192', type: 'image/png' },
      { src: '/icon', sizes: '512x512', type: 'image/png' },
    ],
  };
}
