# MATRIZ DE RESPONSABILIDADE — ASSISTENTE DE CANETA

> Documento interno + anexo para o advogado. Define **quem responde pelo quê** em cada camada do serviço.

| # | Atividade / Risco | Responsável | Fundamento | Mitigação implementada |
|---|---|---|---|---|
| 1 | Prescrição da medicação | **Médico do paciente** | Lei 12.842/2013 (Ato Médico); Res. CFM | App exige declaração de prescrição prévia; não sugere doses |
| 2 | Decisão de iniciar/parar/ajustar tratamento | **Paciente + médico** | Autonomia do paciente; relação clínica preexistente | Disclaimers em todas as telas de alerta; textos apenas educativos |
| 3 | Veracidade dos dados registrados (peso, refeições, doses) | **Paciente (autodeclaração)** | Termos de Uso §3.1 | Relatório PDF marca dados como "autodeclarados" |
| 4 | Conteúdo educativo exibido | **Controladora (nós)** | CDC art. 14 | Conteúdo restrito a fontes públicas oficiais com citação (bula Anvisa, ABESO, SBD, ADA); revisão pelo responsável clínico |
| 5 | Exatidão da reprodução de bulas | **Controladora (nós)** | CDC art. 14 | Base de dados versionada em `database/seeds/` com URL da bula e data de captura; processo de atualização trimestral |
| 6 | Segurança dos dados pessoais | **Controladora (nós)** | LGPD arts. 46-49 | AES-256-GCM, TLS, bcrypt, auditoria, rate limiting — ver docs/SEGURANCA.md |
| 7 | Atos dos operadores (Railway, Resend, Sentry) | **Controladora + operador solidariamente** | LGPD art. 42, §1º | Contratos com cláusulas de proteção de dados; scrubbing de PII no Sentry |
| 8 | Acesso indevido pelo profissional convidado | **Profissional** (com dever nosso de auditoria) | Códigos de ética CFM/CFN; LGPD art. 42 | Acesso somente-leitura, mediante convite do paciente, com log de auditoria imutável |
| 9 | Uso do app por menor de idade com dados falsos | **Responsáveis legais do menor** | Termos §1.3 | Verificação de data de nascimento; exclusão de contas identificadas |
| 10 | Supervisão clínica do conteúdo do app | **Responsável clínico (CRM/CRN contratado)** | Boas práticas SaMD | Nomeação formal com anotação de responsabilidade técnica — **PENDENTE: contratar profissional** |
| 11 | Farmacovigilância (reações adversas) | **Paciente/médico notificam VigiMed** | RDC 406/2020 | App exibe link/instrução de notificação VigiMed quando usuário registra efeito adverso grave |
| 12 | Publicidade do app | **Controladora (nós)** | CDC arts. 36-37; RDC 96/2008 (não fazer propaganda de medicamento) | Marketing NUNCA cita marcas de medicamento como incentivo; apenas "acompanhamento de tratamento prescrito" |

## Pontos de atenção para o advogado

1. **Item 10 é bloqueador de launch** — precisamos de um profissional de saúde como responsável clínico nomeado.
2. Confirmar se o enquadramento como **software de bem-estar/registro** (fora do escopo SaMD de risco — RDC 657/2022, art. 4º) se sustenta, dado que o app **não diagnostica nem trata** (ver CONFORMIDADE_ANVISA.md).
3. Validar a redação da limitação de responsabilidade (Termos §8) frente ao CDC.
4. Validar transferência internacional de dados (Resolução ANPD nº 19/2024) conforme região final do deploy.
