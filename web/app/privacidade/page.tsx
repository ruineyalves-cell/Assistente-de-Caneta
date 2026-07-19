import type { Metadata } from 'next';
import LegalLayout from '@/components/legal-layout';
import { secoesTermos, versaoTermos } from '@/lib/termos';

export const metadata: Metadata = {
  title: 'Política de Privacidade',
  description:
    'Como o Recorpo protege seus dados de saúde e cumpre a LGPD e o padrão HIPAA.',
};

export default function PrivacidadePage() {
  // Da lista completa, exibimos aqui as seções que tratam
  // diretamente de dados (3), padrão HIPAA (4) e direitos do titular
  // (parte de 2, 5, 8). O corpo integral fica em /termos.
  const secoes = secoesTermos.filter((s) =>
    ['1', '3', '4', '5', '8'].includes(s.numero)
  );

  return (
    <LegalLayout
      titulo="Política de Privacidade"
      subtitulo={`Versão ${versaoTermos} · aplicável a partir da instalação do Recorpo.`}
    >
      <div className="space-y-8">
        {secoes.map((s) => (
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
          Para solicitar acesso, correção, exportação ou exclusão dos seus
          dados, escreva para{' '}
          <a
            href="mailto:contato@recorpo.com.br"
            className="text-brand-primaryLight underline underline-offset-2"
          >
            contato@recorpo.com.br
          </a>{' '}
          — respondemos em até 15 dias corridos.
        </p>
      </div>
    </LegalLayout>
  );
}
