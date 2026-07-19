const { z } = require('zod');
const patientModel = require('../models/patientModel');
const medicationModel = require('../models/medicationModel');
const linkModel = require('../models/linkModel');
const userModel = require('../models/userModel');
const dailyLogModel = require('../models/dailyLogModel');
const db = require('../config/db');
const { calcularFatos } = require('../utils/preConsulta');
const { selecionarPerguntas } = require('../utils/perguntasPreConsulta');

// Lote 31 — enums espelham lib/models/patient_profile.dart no cliente.
// Mantidos como strings livres (VARCHAR) porque a lista pode evoluir
// junto com a farmacologia; a validação de conjunto fica no cliente.
const perfilSchema = z.object({
  medicationId: z.number().int().positive().optional(),
  doseAtual: z.string().max(30).optional(),
  frequencia: z.string().max(40).optional(),
  pesoInicialKg: z.number().min(20).max(400).optional(),
  alturaCm: z.number().min(100).max(250).optional(),
  declarouPrescricao: z.boolean(),
  metaProteinaGkg: z.number().min(0.8).max(2.5).optional(),
  metaAguaMlKg: z.number().min(20).max(60).optional(),
  // Perfil estendido — vinham só como shared_preferences no cliente.
  eixoFarmacologico: z.string().max(40).optional(),
  identidadeGenero: z.string().max(30).optional(),
  sexoBiologico: z.string().max(30).optional(),
  ultimaDoseIso: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Data ISO YYYY-MM-DD').optional(),
  metaPesoKg: z.number().min(20).max(400).optional(),
});

/** PUT /api/pacientes/perfil */
async function salvarPerfil(req, res, next) {
  try {
    const d = perfilSchema.parse(req.body);
    // A declaração de prescrição é exigida apenas quando o payload
    // efetivamente traz dados de medicação (id, dose ou frequência).
    // Peso/altura/metas isoladamente não requerem declaração — são
    // dados clínicos gerais que ajudam o dashboard mesmo sem GLP-1.
    const tocaMedicacao = d.medicationId != null ||
      (d.doseAtual != null && d.doseAtual !== '') ||
      (d.frequencia != null && d.frequencia !== '');
    if (tocaMedicacao && !d.declarouPrescricao) {
      return res.status(403).json({
        erro: 'É necessário declarar que possui prescrição médica para a medicação (Termos de Uso §3.1).',
      });
    }
    if (d.medicationId) {
      const med = await medicationModel.porId(d.medicationId);
      if (!med || !med.ativo || med.status_anvisa !== 'aprovado') {
        return res.status(400).json({ erro: 'Medicação inválida ou não aprovada pela Anvisa.' });
      }
    }
    await patientModel.upsertPerfil(req.user.id, d);
    const perfil = await patientModel.perfil(req.user.id);
    return res.json({ perfil });
  } catch (err) { next(err); }
}

/** GET /api/pacientes/perfil */
async function obterPerfil(req, res, next) {
  try {
    const perfil = await patientModel.perfil(req.user.id);
    return res.json({ perfil });
  } catch (err) { next(err); }
}

/** POST /api/pacientes/profissionais — convida profissional por e-mail. */
async function convidarProfissional(req, res, next) {
  try {
    const { email } = z.object({ email: z.string().email() }).parse(req.body);
    const prof = await userModel.porEmail(email);
    if (!prof || prof.role !== 'profissional') {
      return res.status(404).json({ erro: 'Profissional não encontrado. Ele precisa criar conta como profissional primeiro.' });
    }
    const { rows } = await db.query(
      `SELECT verificado FROM professional_profiles WHERE user_id = $1`, [prof.id]
    );
    const vinculo = await linkModel.convidar(req.user.id, prof.id);
    return res.status(201).json({
      vinculo,
      aviso: rows[0]?.verificado ? undefined :
        'Este profissional ainda não teve o registro (CRM/CRN) verificado. O acesso dele ao portal só é liberado após verificação.',
    });
  } catch (err) { next(err); }
}

/** DELETE /api/pacientes/profissionais/:id — revoga acesso. */
async function revogarProfissional(req, res, next) {
  try {
    await linkModel.revogar(req.user.id, req.params.id);
    return res.json({ ok: true });
  } catch (err) { next(err); }
}

/** GET /api/pacientes/profissionais */
async function listarProfissionais(req, res, next) {
  try {
    const profissionais = await linkModel.profissionaisDoPaciente(req.user.id);
    return res.json({ profissionais });
  } catch (err) { next(err); }
}

/**
 * GET /api/pacientes/pre-consulta
 *
 * Lote 32.2 — Pré-consulta determinística (sem IA).
 *
 * Retorna um resumo objetivo dos últimos 30 dias + até 5 perguntas
 * curadas para o paciente levar ao médico. Nada é gerado por IA;
 * tudo vem de utils/preConsulta.js + utils/perguntasPreConsulta.js.
 *
 * A resposta inclui um disclaimer que o cliente exibe sempre no topo
 * e no rodapé — reforça que o conteúdo NÃO é diagnóstico e NÃO
 * substitui a avaliação médica.
 */
async function preConsulta(req, res, next) {
  try {
    const janelaDias = 30;
    const hoje = new Date();
    const inicio = new Date(hoje.getTime() - janelaDias * 86_400_000);
    const desde = inicio.toISOString().slice(0, 10);
    const ate = hoje.toISOString().slice(0, 10);

    const [perfil, logs] = await Promise.all([
      patientModel.perfil(req.user.id),
      dailyLogModel.listar(req.user.id, { desde, ate, limite: 200 }),
    ]);

    const fatos = calcularFatos({ perfil, logs, janelaDias });
    const perguntas = selecionarPerguntas(fatos, { limite: 5 });

    return res.json({
      janelaDias,
      geradoEm: hoje.toISOString(),
      disclaimer:
        'Este é um resumo automatizado dos SEUS registros no Recorpo. ' +
        'Não é diagnóstico, não é prescrição e não substitui a avaliação ' +
        'do seu médico.',
      fatos,
      perguntas,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { salvarPerfil, obterPerfil, convidarProfissional, revogarProfissional, listarProfissionais, preConsulta };
