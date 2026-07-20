import type { Metadata } from 'next';
import { Inter, Instrument_Serif } from 'next/font/google';
import './globals.css';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});
const instrument = Instrument_Serif({
  subsets: ['latin'],
  weight: '400',
  style: ['normal', 'italic'],
  variable: '--font-instrument',
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL('https://www.recorpo.com.br'),
  title: {
    default: 'Recorpo — Assistente de Caneta GLP-1',
    template: '%s · Recorpo',
  },
  description:
    'Registre suas aplicações, acompanhe sua evolução e leve um relatório claro para o médico. Recorpo é o companheiro de quem faz tratamento com GLP-1.',
  openGraph: {
    title: 'Recorpo — Assistente de Caneta GLP-1',
    description:
      'Registre, acompanhe e compartilhe sua jornada de tratamento GLP-1 com quem cuida de você.',
    type: 'website',
    locale: 'pt_BR',
    url: 'https://www.recorpo.com.br',
    siteName: 'Recorpo',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Recorpo — Assistente de Caneta GLP-1',
    description:
      'Registre, acompanhe e compartilhe sua jornada de tratamento GLP-1.',
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="pt-BR"
      className={`${inter.variable} ${instrument.variable} dark`}
    >
      <body className="font-sans">{children}</body>
    </html>
  );
}
