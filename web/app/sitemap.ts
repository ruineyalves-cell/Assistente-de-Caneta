import type { MetadataRoute } from 'next';

const BASE = 'https://www.recorpo.com.br';

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  return [
    { url: `${BASE}/`, lastModified: now, changeFrequency: 'weekly', priority: 1 },
    { url: `${BASE}/privacidade`, lastModified: now, changeFrequency: 'yearly', priority: 0.6 },
    { url: `${BASE}/termos`, lastModified: now, changeFrequency: 'yearly', priority: 0.6 },
    { url: `${BASE}/suporte`, lastModified: now, changeFrequency: 'monthly', priority: 0.5 },
  ];
}
