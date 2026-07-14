# CHECKLIST PRÉ-LAUNCH — VALIDAÇÃO JURÍDICA E OPERACIONAL

> Nenhum item ⬜ da seção A pode estar pendente no dia do launch público.

## A. Bloqueadores (obrigatórios)

### Jurídico
- [ ] Advogado revisou e aprovou TERMOS_DE_USO_2026.md
- [ ] Advogado revisou e aprovou POLITICA_PRIVACIDADE_LGPD.md
- [ ] Advogado revisou e aprovou DISCLAIMER_MEDICO.md
- [ ] Advogado emitiu parecer sobre CONFORMIDADE_ANVISA.md (enquadramento fora do SaMD)
- [ ] CNPJ constituído com CNAE adequado (62.01-5 desenvolvimento de software; avaliar secundários)
- [ ] DPO/Encarregado nomeado e e-mail publicado (art. 41 LGPD)
- [ ] **Responsável clínico (CRM/CRN) contratado e nomeado** — revisou todo conteúdo educativo

### LGPD técnica (verificar no código antes do deploy)
- [ ] Tela de consentimento destacado para dados de saúde (registro com data/hora/versão)
- [ ] Endpoint de exportação de dados funcional (JSON) — testado
- [ ] Endpoint de exclusão total ("ser esquecido") funcional — testado, com purga de backups em ≤35 dias
- [ ] Log de auditoria registrando todo acesso a dado de saúde
- [ ] Criptografia AES-256-GCM ativa em todos os campos sensíveis (verificar no banco: valores ilegíveis)
- [ ] TLS forçado (HSTS) em produção
- [ ] Scrubbing de PII configurado no Sentry
- [ ] RIPD (Relatório de Impacto) redigido e arquivado

### Conteúdo
- [ ] Toda medicação no banco tem: bula URL oficial + data de captura + revisão do responsável clínico
- [ ] Todo alerta educativo cita fonte e termina com orientação de consultar o médico
- [ ] Nenhum texto do app usa verbos de conduta clínica ("tome", "aumente", "suspenda")

## B. Fortemente recomendados

- [ ] Registro da marca "Assistente de Caneta" no INPI (classe 9 e 42)
- [ ] Seguro de responsabilidade civil profissional (E&O) — cotar
- [ ] Termo de uso do Portal Profissional assinado eletronicamente pelo profissional no primeiro acesso
- [ ] Política de resposta a incidentes escrita (quem faz o quê nas primeiras 72h — Res. ANPD 15/2024)
- [ ] Teste de restauração de backup executado com sucesso
- [ ] Pentest básico ou scan de vulnerabilidades (OWASP ZAP) executado

## C. Lojas de aplicativo

- [ ] Google Play: Data Safety form preenchido (dados de saúde = declarar!)
- [ ] Google Play: categoria "Saúde e fitness" (NÃO "Médico")
- [ ] Apple App Store: App Privacy details + justificativa HealthKit se aplicável
- [ ] Idade mínima 18+ configurada nas duas lojas
- [ ] Texto das lojas sem menção promocional a marcas de medicamento (RDC 96/2008)

## D. Dossiê para o advogado (entregar junto)

1. `juridico/` completo (este diretório)
2. `docs/ARQUITETURA.md` + `docs/SEGURANCA.md`
3. `database/seeds/001_medications.sql` (fontes das informações de medicação)
4. Prints das telas de consentimento e disclaimers
5. Este checklist com status atual
