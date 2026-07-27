const { Router } = require('express');
const { requireAuth, requireRole } = require('../middleware/auth');
const { audit, requireConsent } = require('../middleware/lgpd');
const { authLimiter, iaLimiter, subscriptionLimiter } = require('../middleware/rateLimiter');

const auth = require('../controllers/authController');
const meds = require('../controllers/medicationController');
const patient = require('../controllers/patientController');
const logs = require('../controllers/dailyLogController');
const doctor = require('../controllers/doctorController');
const lgpd = require('../controllers/lgpdController');
const ia = require('../controllers/iaController');
const sub = require('../controllers/subscriptionController');

const r = Router();

// --- Auth (rate limit agressivo) ---
r.post('/auth/registrar', authLimiter, auth.registrar);
r.post('/auth/login', authLimiter, auth.login);
r.post('/auth/refresh', authLimiter, auth.refresh);
r.post('/auth/logout', requireAuth, auth.logout);
// Lote 20 — Login social (Google agora; Apple depois).
r.post('/auth/oauth-social', authLimiter, auth.oauthSocial);

// --- Catálogo público de medicações (dados de bula — sem autenticação) ---
r.get('/medicacoes', meds.listar);
r.get('/medicacoes/:id', meds.detalhe);

// --- LGPD (autenticado; consentimento é o único endpoint de saúde sem requireConsent) ---
r.post('/lgpd/consentimento', requireAuth, lgpd.registrarConsentimento);
r.get('/lgpd/consentimentos', requireAuth, lgpd.listarConsentimentos);
r.get('/lgpd/exportar', requireAuth, audit('export', 'todos_os_dados'), lgpd.exportarDados);
r.get('/lgpd/acessos', requireAuth, lgpd.listarAcessos);
r.delete('/lgpd/conta', requireAuth, audit('delete', 'conta'), lgpd.excluirConta);

// --- Paciente (exige consentimento LGPD para dados de saúde) ---
const paciente = [requireAuth, requireRole('paciente'), requireConsent];
r.put('/pacientes/perfil', ...paciente, audit('update', 'patient_profile'), patient.salvarPerfil);
r.get('/pacientes/perfil', ...paciente, audit('read', 'patient_profile'), patient.obterPerfil);
// Lote 32.2 — Pré-consulta determinística. Auditamos como "read" em
// daily_logs porque a agregação passa por todos os logs do mês.
r.get('/pacientes/pre-consulta', ...paciente, audit('read', 'pre_consulta'), patient.preConsulta);
// Lote 32.4 — Alertas clínicos objetivos (sintoma persistente etc.).
r.get('/pacientes/alertas', ...paciente, audit('read', 'alertas'), patient.alertas);
// Lote 32.3 — Resumo diário determinístico.
r.get('/pacientes/resumo-diario', ...paciente, audit('read', 'resumo_diario'), patient.resumoDiario);
r.get('/pacientes/profissionais', ...paciente, patient.listarProfissionais);
r.post('/pacientes/profissionais', ...paciente, patient.convidarProfissional);
r.delete('/pacientes/profissionais/:id', ...paciente, patient.revogarProfissional);

r.post('/logs', ...paciente, audit('create', 'daily_logs'), logs.registrar);
r.get('/logs', ...paciente, audit('read', 'daily_logs'), logs.listar);
r.get('/logs/dashboard', ...paciente, audit('read', 'dashboard'), logs.dashboard);

// --- IA de visão (Lote 21). Paciente autenticado com consentimento;
// auditamos como "read" porque a imagem passa pelo servidor mas
// deliberadamente NÃO persiste em disco (só pra IA externa efêmera).
// iaLimiter (Lote G1): 15 req/min por usuário — evita abuso de cota
// da Gemini se conta for comprometida ou app entrar em loop.
r.post('/ia/refeicao', ...paciente, iaLimiter, audit('read', 'ia_refeicao'), ia.analisar);
// Lote 32.8 — Rótulo alimentar + bula (mesma engine Gemini).
r.post('/ia/rotulo', ...paciente, iaLimiter, audit('read', 'ia_rotulo'), ia.analisarRotulo);
r.post('/ia/bula', ...paciente, iaLimiter, audit('read', 'ia_bula'), ia.analisarBula);

// --- Assinatura Premium via Play Billing.
// validar: chamado UMA vez após purchase confirmar no app.
// status: consultado sempre que o app precisa checar Premium (com cache 12h).
// rtdn: webhook Pub/Sub do Play — NÃO autenticado por JWT, protegido por
// segredo compartilhado opcional (RTDN_SHARED_SECRET) + re-consulta Play
// sempre pra validar (nunca confia no payload).
r.post('/assinaturas/validar', requireAuth, subscriptionLimiter, audit('create', 'subscription'), sub.validar);
r.get('/assinaturas/status', requireAuth, sub.status);
r.post('/assinaturas/rtdn', sub.rtdn);

// --- Portal do profissional (read-only; auditoria com titular = paciente acessado) ---
const prof = [requireAuth, requireRole('profissional')];
const donoPaciente = (req) => req.params.id;
r.get('/portal/pacientes', ...prof, doctor.listarPacientes);
r.get('/portal/pacientes/:id', ...prof, audit('read', 'daily_logs', donoPaciente), doctor.verPaciente);
r.get('/portal/pacientes/:id/relatorio.pdf', ...prof, audit('export', 'relatorio_pdf', donoPaciente), doctor.relatorioPdf);

module.exports = r;
