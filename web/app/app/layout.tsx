import type { Metadata, Viewport } from 'next';
import { AuthProvider } from './_lib/auth-provider';

export const metadata: Metadata = {
  title: 'Recorpo — Assistente GLP-1',
  description:
    'Registro diário de doses, hidratação, peso e sintomas do seu tratamento GLP-1.',
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  themeColor: '#0B1220',
};

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AuthProvider>{children}</AuthProvider>;
}
