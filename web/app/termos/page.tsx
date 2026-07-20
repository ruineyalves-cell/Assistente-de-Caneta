import type { Metadata } from 'next';
import LegalLayout from '@/components/legal-layout';
import { secoesTermos, versaoTermos, dataVigencia } from '@/lib/termos';

export const metadata: Metadata = {
  title: 'Termos de Uso',
  description:
    'Termos de Uso do Recorpo — natureza do aplicativo, direitos e deveres do usuário.',
};

export default function TermosPage() {
  return (
    <LegalLayout
      titulo="Termos de Uso"
      subtitulo={`Recorpo (Assistente de Caneta) · versão ${versaoTermos} · em vigor a partir de ${dataVigencia}.`}
    >
      <div className="space-y-8">
        {secoesTermos.map((s) => (
          <div key={s.numero}>
            <h2 className="font-serif text-2xl text-recorpo-text mb-3">
              {s.numero}. {s.titulo}
            </h2>
            <div className="space-y-2">
              {s.paragrafos.map((p, i) => (
                <p key={i}>{p}</p>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-14 p-6 rounded-2xl border border-white/[0.08] bg-recorpo-surface/60">
        <p className="text-sm text-recorpo-dim">
          Ao instalar e usar o Recorpo, você declara ter lido e concordado com
          estes Termos e com nossa{' '}
          <a
            href="/privacidade"
            className="text-brand-primaryLight underline underline-offset-2"
          >
            Política de Privacidade
          </a>
          , consentindo com o tratamento dos seus dados de saúde para a
          finalidade de acompanhamento de conformidade.
        </p>
      </div>
    </LegalLayout>
  );
}
