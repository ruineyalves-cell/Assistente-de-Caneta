/**
 * Texto legal consolidado — espelho de
 * `flutter_app/lib/utils/constants.dart` (AppConstants.termosLegaisTexto).
 * Fonte única quando quisermos evoluir os termos: atualizar aqui e no
 * app Flutter juntos. A versão do documento vive na primeira linha do
 * bloco; quando mudar, incrementar `versaoTermos`.
 */
export const versaoTermos = '0.1.0 (beta)';

/**
 * Corpo integral dos termos, seguindo a estrutura numerada que já
 * mostramos na tela DisclaimerScreen do app. Cada tópico vira uma
 * seção com título forte e corpo em texto corrido.
 */
export const secoesTermos: Array<{
  numero: string;
  titulo: string;
  paragrafos: string[];
}> = [
  {
    numero: '1',
    titulo: 'Natureza do aplicativo',
    paragrafos: [
      'Este aplicativo é uma ferramenta educacional de registro e acompanhamento de conformidade para pessoas em tratamento com medicamentos da classe GLP-1/GIP. Ele NÃO fornece diagnóstico, NÃO substitui a orientação de profissionais de saúde e NÃO é um dispositivo médico.',
    ],
  },
  {
    numero: '2',
    titulo: 'Uso permitido',
    paragrafos: [
      '2.1. O uso é permitido apenas para maiores de 18 anos.',
      '2.2. Você é responsável pela veracidade dos dados que registra.',
      '2.3. As informações educativas exibidas são reproduções de fontes oficiais (bulas Anvisa, ABESO, Ministério da Saúde, ADA), sempre citadas.',
    ],
  },
  {
    numero: '3',
    titulo: 'Dados e privacidade (LGPD — Lei 13.709/2018)',
    paragrafos: [
      '3.1. Seus dados de saúde são dados sensíveis e tratados com base no seu consentimento (art. 11).',
      '3.2. Os dados são criptografados em trânsito (HTTPS) e sensíveis são cifrados no servidor.',
      '3.3. Você pode, a qualquer momento: acessar, corrigir, exportar e solicitar a exclusão dos seus dados.',
      '3.4. A exclusão remove sua conta e agenda a eliminação definitiva dos dados em até 30 dias.',
      '3.5. Não vendemos nem compartilhamos seus dados com terceiros para fins de marketing.',
    ],
  },
  {
    numero: '4',
    titulo: 'Padrão internacional de sigilo (HIPAA)',
    paragrafos: [
      '4.1. Ainda que a norma aplicável ao Brasil seja a LGPD, quando os dados forem processados por infraestrutura sediada nos Estados Unidos ou por prestadores sujeitos à Health Insurance Portability and Accountability Act (HIPAA), o mesmo padrão de sigilo é observado: seus dados de saúde são tratados como Protected Health Information (PHI), com acesso restrito, registro de auditoria e ciframento em repouso.',
      '4.2. Não realizamos venda de PHI e não usamos PHI para publicidade dirigida.',
    ],
  },
  {
    numero: '5',
    titulo: 'Limitação de responsabilidade',
    paragrafos: [
      '5.1. As decisões sobre sua medicação, dose e tratamento devem ser sempre tomadas com seu médico.',
      '5.2. O aplicativo não se responsabiliza por decisões tomadas exclusivamente com base nos registros ou alertas exibidos.',
    ],
  },
  {
    numero: '6',
    titulo: 'Segurança',
    paragrafos: [
      '6.1. Mantenha sua senha em sigilo.',
      '6.2. Em caso de suspeita de acesso indevido, altere sua senha.',
    ],
  },
  {
    numero: '7',
    titulo: 'Alterações',
    paragrafos: [
      'Estes termos podem ser atualizados. Mudanças relevantes serão comunicadas no aplicativo.',
    ],
  },
  {
    numero: '8',
    titulo: 'Contato',
    paragrafos: [
      'Dúvidas sobre privacidade e seus direitos podem ser encaminhadas ao controlador dos dados pelo canal de suporte informado no aplicativo, ou pelo e-mail contato@recorpo.com.br.',
    ],
  },
];
