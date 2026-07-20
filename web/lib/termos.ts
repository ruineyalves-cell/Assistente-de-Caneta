/**
 * Texto legal consolidado do Recorpo — política de privacidade e termos de uso.
 * Espelho de `flutter_app/lib/utils/constants.dart` (AppConstants.termosLegaisTexto).
 * Fonte única quando quisermos evoluir os termos: atualizar aqui e no
 * app Flutter juntos. Ao editar, incrementar `versaoTermos` e atualizar
 * `dataVigencia`.
 */
export const versaoTermos = '1.0.0';
export const dataVigencia = '20 de julho de 2026';

// ============================================================================
// TERMOS DE USO
// ============================================================================

export const secoesTermos: Array<{
  numero: string;
  titulo: string;
  paragrafos: string[];
}> = [
  {
    numero: '1',
    titulo: 'Natureza do aplicativo',
    paragrafos: [
      'O Recorpo é uma ferramenta educacional de registro e acompanhamento de conformidade para pessoas em tratamento com medicamentos da classe GLP-1/GIP (por exemplo, semaglutida, liraglutida, tirzepatida).',
      'O Recorpo NÃO fornece diagnóstico, NÃO prescreve tratamento, NÃO substitui a orientação de profissionais de saúde e NÃO é um dispositivo médico regulado pela Anvisa.',
      'Todas as decisões sobre uso, dose e ajustes de medicação devem ser tomadas com o profissional de saúde responsável pelo seu tratamento.',
    ],
  },
  {
    numero: '2',
    titulo: 'Uso permitido',
    paragrafos: [
      '2.1. O uso é permitido apenas para maiores de 18 anos. Ao criar sua conta você declara ter idade legal.',
      '2.2. Você é o único responsável pela veracidade dos dados que registra no aplicativo.',
      '2.3. As informações educativas exibidas (por exemplo, sintomas, faixas de referência, alertas) são reproduções de fontes oficiais — bulas Anvisa, ABESO, Ministério da Saúde, OMS e ADA — sempre citadas.',
      '2.4. É proibido usar o aplicativo para fins comerciais, coletar dados de outras pessoas, aplicar engenharia reversa ou revender o serviço sem autorização por escrito.',
    ],
  },
  {
    numero: '3',
    titulo: 'Conta e senha',
    paragrafos: [
      '3.1. A criação de conta pode ser feita por e-mail e senha ou por login social (Google).',
      '3.2. Você é responsável por manter sua senha em sigilo. Em caso de suspeita de acesso indevido, altere a senha imediatamente e comunique o suporte.',
      '3.3. O Recorpo pode encerrar contas com uso abusivo, fraudulento ou que violem estes termos.',
    ],
  },
  {
    numero: '4',
    titulo: 'Assinatura Premium',
    paragrafos: [
      '4.1. O Recorpo é gratuito para os recursos essenciais. Recursos avançados (reconhecimento por foto ilimitado, PDF médico enriquecido, comparativos históricos estendidos) fazem parte da assinatura Recorpo Premium, oferecida via Google Play Billing.',
      '4.2. Valores atuais: R$ 19,90/mês (com 7 dias de teste grátis) e R$ 149,90/ano (com 30 dias de teste grátis). Preços podem ser reajustados mediante aviso prévio de 30 dias.',
      '4.3. A assinatura é renovada automaticamente pela Google Play até que você a cancele nas configurações do Google Play. Cancelar impede novas cobranças e o Premium fica ativo até o fim do ciclo já pago.',
      '4.4. Reembolsos seguem a política do Google Play, disponível em https://support.google.com/googleplay/answer/2479637.',
    ],
  },
  {
    numero: '5',
    titulo: 'Limitação de responsabilidade',
    paragrafos: [
      '5.1. O Recorpo é oferecido "no estado em que se encontra". Faremos esforço para manter o serviço disponível, mas não garantimos operação ininterrupta ou livre de erros.',
      '5.2. O Recorpo não se responsabiliza por decisões clínicas, sinistros de saúde ou danos decorrentes de decisões tomadas exclusivamente com base nos registros, alertas ou conteúdo educativo exibidos.',
      '5.3. A responsabilidade máxima do Recorpo em qualquer situação está limitada ao valor efetivamente pago pela assinatura nos últimos 12 meses.',
    ],
  },
  {
    numero: '6',
    titulo: 'Alterações destes termos',
    paragrafos: [
      'Estes termos podem ser atualizados a qualquer momento. Mudanças relevantes serão comunicadas no aplicativo com antecedência de 15 dias. O uso continuado após a data de vigência da nova versão significa aceitação.',
    ],
  },
  {
    numero: '7',
    titulo: 'Foro',
    paragrafos: [
      'Aplica-se a legislação brasileira. Fica eleito o foro da comarca de São Paulo — SP para dirimir eventuais controvérsias.',
    ],
  },
];

// ============================================================================
// POLÍTICA DE PRIVACIDADE (LGPD — Lei 13.709/2018)
// ============================================================================

export const secoesPrivacidade: Array<{
  numero: string;
  titulo: string;
  paragrafos: string[];
}> = [
  {
    numero: '1',
    titulo: 'Quem é o controlador dos seus dados',
    paragrafos: [
      'O controlador dos dados pessoais tratados pelo Recorpo é o desenvolvedor responsável pelo aplicativo, identificado nos metadados da Play Store.',
      'Encarregado pelo Tratamento de Dados (DPO): dpo@recorpo.com.br',
      'Canal geral de atendimento: contato@recorpo.com.br',
    ],
  },
  {
    numero: '2',
    titulo: 'Quais dados coletamos e por quê',
    paragrafos: [
      'a) Dados de cadastro: nome, e-mail, senha (com hash bcrypt) — para criar e proteger sua conta.',
      'b) Dados de saúde (sensíveis, art. 5º II da LGPD): peso, hidratação, refeições, sintomas, medicação em uso, doses aplicadas, resultados de exames que você opte por registrar — para oferecer o serviço.',
      'c) Fotos: imagens de prato, rótulo, bula ou prescrição enviadas voluntariamente para reconhecimento por IA — processadas e não armazenadas em servidor após a resposta.',
      'd) Dados de uso: eventos técnicos anonimizados (crash, tempo de resposta) — para diagnosticar problemas.',
      'e) Dados de pagamento: NÃO coletamos dados de cartão. A cobrança da assinatura é processada integralmente pelo Google Play Billing.',
    ],
  },
  {
    numero: '3',
    titulo: 'Bases legais',
    paragrafos: [
      'Dados de saúde (sensíveis): tratados com base no seu consentimento específico (art. 11, I da LGPD), coletado explicitamente na primeira abertura do aplicativo. Você pode revogar a qualquer momento excluindo sua conta.',
      'Dados de cadastro e uso: tratados com base na execução do contrato entre você e o Recorpo (art. 7º, V da LGPD).',
      'Dados de crash e desempenho: tratados com base no legítimo interesse (art. 7º, IX), respeitando sua expectativa e sem impacto em direitos fundamentais.',
    ],
  },
  {
    numero: '4',
    titulo: 'Com quem compartilhamos',
    paragrafos: [
      'Compartilhamos dados apenas com operadores estritamente necessários ao funcionamento do serviço, sob contrato:',
      'a) Google LLC — autenticação (Firebase Authentication) e pagamentos (Google Play Billing). Dados: e-mail e identificador da conta Google, quando você opta por login social; identificador da compra, quando assina Premium.',
      'b) Render.com — hospedagem do servidor de aplicação nos EUA. Dados: todos os dados armazenados na sua conta, cifrados em trânsito (TLS 1.3) e sensíveis também em repouso.',
      'c) Google Gemini API — reconhecimento de imagem por IA, apenas quando você envia uma foto para análise de refeição, rótulo, bula ou prescrição. A foto é processada e descartada após a resposta.',
      'Não vendemos, não alugamos e não compartilhamos seus dados para fins de publicidade ou marketing por terceiros.',
    ],
  },
  {
    numero: '5',
    titulo: 'Onde ficam armazenados',
    paragrafos: [
      'Os dados ficam armazenados em infraestrutura da Render.com (região dos EUA). Quando os dados são processados fora do Brasil, aplicamos padrão de proteção equivalente ao HIPAA (Health Insurance Portability and Accountability Act), tratando dados de saúde como Protected Health Information (PHI), com acesso restrito, registro de auditoria e ciframento em repouso.',
      'Não realizamos venda de PHI e não usamos PHI para publicidade dirigida.',
    ],
  },
  {
    numero: '6',
    titulo: 'Por quanto tempo mantemos',
    paragrafos: [
      'Dados de saúde e uso: mantidos enquanto sua conta estiver ativa. Ao excluir a conta, agendamos a eliminação em até 30 dias corridos, exceto quando obrigados a reter por lei (por exemplo, dados fiscais de assinatura por 5 anos, Lei 5.172/1966).',
      'Registros de acesso: 6 meses, para atender ao Marco Civil da Internet (art. 15).',
      'Backups: os backups podem conter dados excluídos por até 90 dias, quando são sobrescritos.',
    ],
  },
  {
    numero: '7',
    titulo: 'Seus direitos (LGPD art. 18)',
    paragrafos: [
      'A qualquer momento você pode, direto pelo aplicativo (menu Perfil → Meus dados) ou pelo e-mail dpo@recorpo.com.br:',
      'I — confirmar a existência de tratamento;',
      'II — acessar seus dados;',
      'III — corrigir dados incompletos, inexatos ou desatualizados;',
      'IV — anonimizar, bloquear ou eliminar dados desnecessários, excessivos ou tratados em desconformidade;',
      'V — solicitar a portabilidade dos dados a outro fornecedor (exportação em JSON legível);',
      'VI — eliminar dados pessoais tratados com base no seu consentimento;',
      'VII — obter informação sobre entidades públicas e privadas com quem compartilhamos dados;',
      'VIII — ser informado sobre a possibilidade de não fornecer consentimento e sobre as consequências disso;',
      'IX — revogar o consentimento a qualquer tempo.',
      'Responderemos em até 15 dias corridos.',
    ],
  },
  {
    numero: '8',
    titulo: 'Segurança',
    paragrafos: [
      'Adotamos medidas técnicas e administrativas para proteger seus dados: TLS 1.3 no transporte, hash bcrypt para senhas, ciframento AES-256 para dados sensíveis em repouso, tokens JWT com expiração curta, PIN/biometria opcional dentro do aplicativo, controle de acesso por função, backups criptografados, registros de auditoria.',
      'Ainda assim, nenhum sistema é 100% imune. Em caso de incidente de segurança relevante, comunicaremos você e a Autoridade Nacional de Proteção de Dados (ANPD) em prazo razoável, conforme art. 48 da LGPD.',
    ],
  },
  {
    numero: '9',
    titulo: 'Menores de idade',
    paragrafos: [
      'O Recorpo é destinado a maiores de 18 anos. Não coletamos, com conhecimento, dados de crianças ou adolescentes. Se identificarmos coleta indevida, os dados serão eliminados imediatamente.',
    ],
  },
  {
    numero: '10',
    titulo: 'Cookies e armazenamento local',
    paragrafos: [
      'O site www.recorpo.com.br usa apenas armazenamento local técnico e essencial (por exemplo, guardar seu token de sessão do Portal Médico). Não usamos cookies de rastreamento, remarketing ou publicidade.',
    ],
  },
  {
    numero: '11',
    titulo: 'Alterações desta política',
    paragrafos: [
      'Esta política pode ser atualizada. A data de vigência acima é sempre atualizada, e mudanças relevantes são comunicadas no aplicativo com 15 dias de antecedência. O uso continuado após a nova data de vigência significa aceitação.',
    ],
  },
  {
    numero: '12',
    titulo: 'Reclamações à ANPD',
    paragrafos: [
      'Se entender que houve violação a esta política ou à LGPD e não estiver satisfeito com nossa resposta, você pode registrar reclamação diretamente à Autoridade Nacional de Proteção de Dados: https://www.gov.br/anpd',
    ],
  },
];
