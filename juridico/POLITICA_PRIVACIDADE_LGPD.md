# POLÍTICA DE PRIVACIDADE — ASSISTENTE DE CANETA

> **MINUTA TÉCNICA — v0.1 (julho/2026)** — elaborada conforme a Lei Geral de Proteção de Dados (Lei 13.709/2018 — "LGPD") e regulamentos da ANPD vigentes. **Validar com advogado antes da publicação.**

---

## 1. Quem somos (Controladora)

[RAZÃO SOCIAL — CNPJ], controladora dos dados pessoais tratados pelo aplicativo **Assistente de Caneta**.
**Encarregado (DPO — art. 41 LGPD):** [nome] — [e-mail exclusivo, ex.: dpo@dominio.com.br].

## 2. Base Legal do Tratamento

Tratamos **dados pessoais sensíveis de saúde** (art. 5º, II, LGPD). O regime aplicável é o do **art. 11**:

| Dado | Base legal | Artigo |
|---|---|---|
| Dados de saúde (medicação, peso, doses, sintomas, alimentação) | **Consentimento específico e destacado** do titular | Art. 11, I |
| Dados cadastrais (nome, e-mail) | Execução de contrato (os Termos de Uso) | Art. 7º, V |
| Logs de acesso e auditoria | Obrigação legal (Marco Civil, art. 15) e legítimo interesse em segurança | Art. 7º, II e IX |
| Dados do profissional de saúde (CRM/CRN) | Execução de contrato + procedimento de verificação | Art. 7º, V |

O consentimento para dados de saúde é coletado em **tela própria, destacada, com linguagem simples**, antes de qualquer coleta, e pode ser **revogado a qualquer momento** (art. 8º, §5º) — a revogação interrompe a coleta e dispara o fluxo de exclusão.

## 3. Quais dados coletamos e por quê (art. 6º — finalidade, adequação, necessidade)

### 3.1 Coletamos:
- **Cadastro:** nome, e-mail, data de nascimento (verificação de maioridade), senha (armazenada apenas como hash bcrypt).
- **Tratamento (inseridos pelo próprio usuário):** medicação prescrita, dose, frequência; peso; proteína consumida; hidratação; descrição de refeições; efeitos percebidos; datas de aplicação.
- **Vínculo profissional (opcional):** nome e registro (CRM/CRN) do profissional convidado pelo usuário.
- **Técnicos:** logs de acesso (IP, data/hora), identificador do dispositivo, versão do app.

### 3.2 NÃO coletamos:
- Geolocalização contínua, contatos, microfone, fotos além das enviadas voluntariamente (ex.: receituário para OCR), dados de navegação fora do App.
- **Não usamos dados para publicidade. Não vendemos dados. Nunca.**

### 3.3 Finalidades (exaustivas):
1. Exibir ao usuário seu próprio histórico e métricas de conformidade;
2. Gerar alertas educativos determinísticos baseados em fontes públicas;
3. Permitir que profissional convidado pelo usuário visualize os dados (leitura);
4. Gerar relatório PDF a pedido do usuário;
5. Segurança, prevenção a fraude e cumprimento legal.

Qualquer finalidade nova exigirá **novo consentimento**.

## 4. Compartilhamento (Operadores — art. 39)

| Operador | Serviço | Dados | Local |
|---|---|---|---|
| Railway (infra) | Hospedagem backend + banco | Todos (criptografados) | [região São Paulo/US — definir; se fora do Brasil, transferência internacional nos termos dos arts. 33-36 e Resolução ANPD nº 19/2024] |
| Resend | E-mails transacionais | Nome, e-mail | EUA (cláusulas contratuais padrão) |
| Sentry | Monitoramento de erros | Dados técnicos anonimizados (scrubbing de PII ativado) | EUA |
| Google Cloud Vision (fase 2) | OCR de receituário | Imagem enviada voluntariamente (descartada após extração) | EUA |

Nenhum outro compartilhamento ocorre, salvo ordem judicial ou requisição de autoridade competente (com registro e, quando lícito, notificação ao titular).

## 5. Segurança (art. 46)

- Criptografia **AES-256-GCM** para dados de saúde em repouso (campo a campo);
- **TLS 1.2+** em todo o tráfego;
- Senhas com **bcrypt** (custo ≥ 12); tokens JWT de curta duração + refresh token revogável;
- **Logs de auditoria imutáveis**: todo acesso a dado de saúde registra quem, quando e o quê (art. 37);
- Princípio do menor privilégio; profissional só lê dados de quem o convidou;
- Backups criptografados; segregação de ambientes; rate limiting contra força bruta.

## 6. Direitos do Titular (arts. 17–22)

Você pode exercer, **gratuitamente e dentro do próprio App** (ou pelo e-mail do DPO):

| Direito | Como | Prazo |
|---|---|---|
| **Confirmação e acesso** (art. 18, I-II) | Tela "Meus Dados" | Imediato |
| **Correção** (art. 18, III) | Edição no App | Imediato |
| **Portabilidade** (art. 18, V) | Botão "Exportar meus dados" — JSON/PDF | Imediato |
| **Eliminação / "ser esquecido"** (art. 18, VI) | Botão "Excluir conta e dados" | Efetiva em até 30 dias |
| **Informação sobre compartilhamento** (art. 18, VII) | Esta política + tela "Quem acessou meus dados" | Imediato |
| **Revogação do consentimento** (art. 8º, §5º) | Tela de privacidade | Imediato |

Reclamações podem ser dirigidas à **ANPD** (gov.br/anpd).

## 7. Retenção e Eliminação

- Dados de saúde: mantidos enquanto a conta estiver ativa; eliminados em até **30 dias** após solicitação de exclusão.
- Logs de acesso: **6 meses** (art. 15, Marco Civil da Internet), depois eliminados.
- Registros de consentimento e transações: **5 anos** (prazo prescricional CDC), de forma segregada e minimizada.
- Backups: expiram e são sobrescritos em ciclo máximo de 35 dias após a exclusão.

## 8. Crianças e Adolescentes

O App não se destina a menores de 18 anos e não trata intencionalmente dados de menores (art. 14, LGPD). Contas identificadas como de menores são excluídas.

## 9. Incidentes de Segurança (art. 48)

Incidentes com risco relevante serão comunicados à ANPD e aos titulares afetados nos prazos da Resolução ANPD nº 15/2024 (comunicação preliminar em até 3 dias úteis), com descrição da natureza dos dados, medidas adotadas e recomendações.

## 10. RIPD

Mantemos **Relatório de Impacto à Proteção de Dados Pessoais** (art. 38) atualizado, disponível à ANPD mediante requisição — ver `juridico/CONFORMIDADE_ANVISA.md` e documentação interna.

## 11. Alterações

Mudanças relevantes serão notificadas no App com 10 dias de antecedência e, quando alterarem base legal ou finalidade, exigirão novo consentimento.

---

*Versão 0.1 — [DATA] — pendente de validação jurídica.*
