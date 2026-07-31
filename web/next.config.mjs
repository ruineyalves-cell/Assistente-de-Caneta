/** @type {import('next').NextConfig} */

/**
 * Cabeçalhos de segurança aplicados em TODA rota (Lote I6).
 *
 * CSP é a defesa principal contra XSS: instrui o browser a rejeitar
 * qualquer script/estilo/frame que não venha das origens listadas.
 * 'unsafe-inline' e 'unsafe-eval' estão presentes só onde o Next 14
 * exige (styled-jsx inline, R3F em modo dev). Sem eles o build quebra.
 *
 * Referências:
 *  - MDN CSP: https://developer.mozilla.org/docs/Web/HTTP/CSP
 *  - Next security headers: https://nextjs.org/docs/advanced-features/security-headers
 */
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob:",
  "font-src 'self' data:",
  // fetch pra API do Render (backend Recorpo) — origem já pinada
  "connect-src 'self' https://assistente-caneta-backend-tkl7.onrender.com https://*.onrender.com",
  "frame-ancestors 'none'", // ninguém pode nos embutir em iframe
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
  "upgrade-insecure-requests",
].join('; ');

const securityHeaders = [
  { key: 'Content-Security-Policy', value: csp },
  // HSTS: 1 ano, inclui subdomínios, elegível pra preload list
  { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains; preload' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  // Bloqueia APIs sensíveis que nunca usamos no site (portal médico não
  // acessa câmera/mic/geolocalização). Se um dia o site precisar de
  // câmera pra scanner web, remover 'camera=()' aqui.
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=(), payment=(), usb=()',
  },
];

const nextConfig = {
  reactStrictMode: true,
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  env: {
    NEXT_PUBLIC_API_BASE:
      process.env.NEXT_PUBLIC_API_BASE ??
      'https://assistente-caneta-backend-tkl7.onrender.com',
  },
  async headers() {
    // Permissions-Policy mais permissivo pro /app/* onde o scanner IA
    // precisa da câmera. Fora de /app, câmera continua bloqueada.
    const appPermissions = securityHeaders.map((h) =>
      h.key === 'Permissions-Policy'
        ? {
            key: 'Permissions-Policy',
            value:
              'camera=(self), microphone=(), geolocation=(), interest-cohort=(), payment=(), usb=()',
          }
        : h
    );
    return [
      {
        source: '/app/:path*',
        headers: appPermissions,
      },
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};

export default nextConfig;
