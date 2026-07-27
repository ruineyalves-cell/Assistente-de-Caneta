import type { Metadata } from 'next';
import LegalLayout from '@/components/legal-layout';

export const metadata: Metadata = {
  title: 'Excluir minha conta',
  description:
    'Como solicitar a exclusão da sua conta e dos seus dados no Recorpo — prazos, o que é apagado e o que pode ser retido.',
};

export default function ExcluirContaPage() {
  return (
    <LegalLayout
      titulo="Excluir minha conta"
      subtitulo="A LGPD (art. 18, VI) te garante o direito de apagar seus dados. No Recorpo isso é feito com 3 cliques dentro do app — e você não precisa da nossa aprovação."
    >
      <section className="space-y-5">
        <h2 className="font-serif text-2xl text-recorpo-text">
          1. Pelo próprio app (recomendado)
        </h2>
        <p>
          É o caminho mais rápido: o app cuida de revogar suas sessões antes
          de disparar a exclusão.
        </p>
        <ol className="list-decimal list-inside space-y-2 pl-2">
          <li>Abra o Recorpo e entre com sua conta.</li>
          <li>
            Toque em <strong>Perfil</strong> (canto inferior direito) →{' '}
            <strong>Meus Dados</strong>.
          </li>
          <li>
            Toque em <strong>Excluir minha conta</strong> e confirme duas
            vezes (evitamos toque acidental).
          </li>
        </ol>
        <p>
          Ao confirmar, o app te desloga e mostra o comprovante da solicitação.
        </p>
      </section>

      <section className="space-y-5 mt-12">
        <h2 className="font-serif text-2xl text-recorpo-text">
          2. Por e-mail (se você já apagou o app)
        </h2>
        <p>
          Se você já desinstalou o Recorpo ou não consegue entrar, escreva
          pra{' '}
          <a
            href="mailto:recorpoapp@gmail.com?subject=Excluir%20minha%20conta"
            className="text-brand-primaryLight underline underline-offset-2 font-medium"
          >
            recorpoapp@gmail.com
          </a>{' '}
          com o assunto <strong>&quot;Excluir minha conta&quot;</strong> a partir do
          mesmo endereço que você usou pra criar a conta. Respondemos em até
          2 dias úteis com a confirmação.
        </p>
        <p>
          Se preferir, também vale pedir pela nossa página de{' '}
          <a
            href="/suporte"
            className="text-brand-primaryLight underline underline-offset-2 font-medium"
          >
            suporte
          </a>
          .
        </p>
      </section>

      <section className="space-y-5 mt-12">
        <h2 className="font-serif text-2xl text-recorpo-text">
          3. O que é apagado
        </h2>
        <ul className="space-y-2 pl-5 list-disc">
          <li>Nome, e-mail e credenciais de acesso.</li>
          <li>
            Todos os registros de saúde: peso, hidratação, refeições, sintomas
            e doses aplicadas.
          </li>
          <li>Fotos capturadas pelos scanners de rótulo/bula/refeição.</li>
          <li>
            Vínculos com profissionais de saúde (o convite fica invalidado
            do lado deles também).
          </li>
          <li>Tokens de sessão e histórico de acesso.</li>
        </ul>
      </section>

      <section className="space-y-5 mt-12">
        <h2 className="font-serif text-2xl text-recorpo-text">
          4. Prazos
        </h2>
        <ul className="space-y-3 pl-5 list-disc">
          <li>
            <strong>Imediato</strong> — sua conta é bloqueada, seu e-mail é
            anonimizado (pra não impedir você de se recadastrar depois) e
            todas as sessões são revogadas.
          </li>
          <li>
            <strong>Em até 30 dias</strong> — a purga definitiva remove tudo
            do banco de produção. Esse prazo existe pra permitir
            reverter uma exclusão feita por engano — basta responder ao
            e-mail de confirmação dentro desse período.
          </li>
          <li>
            <strong>Em até 90 dias</strong> — os dados também somem dos
            backups (rodam em ciclo trimestral).
          </li>
        </ul>
      </section>

      <section className="space-y-5 mt-12">
        <h2 className="font-serif text-2xl text-recorpo-text">
          5. O que pode ser retido
        </h2>
        <p>
          A LGPD (art. 16) permite reter dados estritamente necessários para
          <em> cumprimento de obrigação legal ou regulatória</em>. No Recorpo
          isso se resume a:
        </p>
        <ul className="space-y-2 pl-5 list-disc">
          <li>
            <strong>Logs de auditoria de segurança</strong> (IP, timestamp,
            evento) — retidos por 6 meses, sem qualquer dado pessoal
            identificável seu além do ID interno anonimizado. Serve pra
            investigar incidentes.
          </li>
          <li>
            <strong>Registros fiscais de assinatura Premium</strong>, quando
            aplicável — mantidos pelo prazo legal exigido pela Receita
            Federal (5 anos), sob responsabilidade do Google Play (o Play é
            quem processa o pagamento, a gente só recebe a confirmação de
            assinatura ativa).
          </li>
        </ul>
      </section>

      <section className="space-y-5 mt-12">
        <h2 className="font-serif text-2xl text-recorpo-text">
          6. Assinatura Premium
        </h2>
        <p>
          Excluir a conta <strong>não cancela</strong> automaticamente sua
          assinatura no Google Play. Se você é Premium, cancele pelo Play
          Store antes:{' '}
          <em>Configurações → Pagamentos e assinaturas → Assinaturas → Recorpo Premium → Cancelar</em>.
          Você mantém acesso Premium até o fim do período pago.
        </p>
      </section>

      <div className="mt-14 p-6 rounded-2xl border border-brand-primary/30 bg-brand-primary/[0.08]">
        <h3 className="font-serif text-2xl text-recorpo-text mb-2">
          Dúvida sobre o processo?
        </h3>
        <p className="text-recorpo-dim">
          Escreve pra{' '}
          <a
            href="mailto:recorpoapp@gmail.com"
            className="text-brand-primaryLight underline underline-offset-2 font-medium"
          >
            recorpoapp@gmail.com
          </a>
          . A gente confirma cada solicitação e responde toda pergunta de
          exclusão em até 2 dias úteis — inclusive quando é só pra tirar
          uma dúvida antes de decidir.
        </p>
      </div>
    </LegalLayout>
  );
}
