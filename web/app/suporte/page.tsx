import type { Metadata } from 'next';
import LegalLayout from '@/components/legal-layout';

export const metadata: Metadata = {
  title: 'Suporte',
  description:
    'Fale com o time do Recorpo — dúvidas frequentes e canal direto.',
};

const FAQ: Array<{ pergunta: string; resposta: string }> = [
  {
    pergunta: 'Preciso de prescrição médica para usar o Recorpo?',
    resposta:
      'O app funciona sem prescrição — você pode acompanhar hidratação, peso e refeições livremente. Registrar dose de medicação, no entanto, exige declarar que você tem prescrição do seu médico, seguindo o §3.1 dos nossos Termos.',
  },
  {
    pergunta: 'O app substitui meu médico?',
    resposta:
      'Não. O Recorpo é uma ferramenta educacional de registro. Ele organiza sua rotina e gera um relatório em PDF que você leva ao consultório — as decisões clínicas ficam sempre com o seu médico.',
  },
  {
    pergunta: 'Como cancelo minha assinatura Premium?',
    resposta:
      'A cobrança é gerenciada pelo Google Play. Vá em Configurações do Play Store → Pagamentos e assinaturas → Assinaturas → Recorpo Premium → Cancelar. Você mantém acesso Premium até o fim do período pago.',
  },
  {
    pergunta: 'Meus dados ficam onde?',
    resposta:
      'Em servidores criptografados, com dados sensíveis cifrados em repouso e trânsito. Você pode exportar ou excluir tudo pelo próprio app, ou solicitar por e-mail em recorpoapp@gmail.com.',
  },
  {
    pergunta: 'Meu médico pode ver meus registros?',
    resposta:
      'Sim, se você convidar. O convite parte do paciente — o profissional só acessa depois que você autoriza no app, e todo acesso fica auditado.',
  },
];

export default function SuportePage() {
  return (
    <LegalLayout
      titulo="Suporte"
      subtitulo="A gente responde rápido. Antes de escrever, dá uma olhada nas dúvidas mais comuns abaixo."
    >
      <div className="space-y-5">
        {FAQ.map((item, i) => (
          <details
            key={i}
            className="group rounded-2xl border border-white/[0.08] bg-recorpo-surface/60 p-5"
          >
            <summary className="cursor-pointer list-none flex items-center justify-between gap-4 text-recorpo-text font-medium">
              <span>{item.pergunta}</span>
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                className="transition-transform group-open:rotate-180 text-recorpo-dim shrink-0"
              >
                <path
                  d="M6 9l6 6 6-6"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </summary>
            <p className="mt-3 text-recorpo-dim text-[15px] leading-relaxed">
              {item.resposta}
            </p>
          </details>
        ))}
      </div>

      <div className="mt-14 p-6 rounded-2xl border border-brand-primary/30 bg-brand-primary/[0.08]">
        <h3 className="font-serif text-2xl text-recorpo-text mb-2">
          Não achou o que precisava?
        </h3>
        <p className="text-recorpo-dim">
          Escreve pra gente em{' '}
          <a
            href="mailto:recorpoapp@gmail.com"
            className="text-brand-primaryLight underline underline-offset-2 font-medium"
          >
            recorpoapp@gmail.com
          </a>{' '}
          — respondemos em até 2 dias úteis. Se for questão médica urgente,
          procure seu médico ou o SAMU (192).
        </p>
      </div>
    </LegalLayout>
  );
}
