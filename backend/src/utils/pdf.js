/**
 * Geração de relatório PDF (pdfkit) — dados autodeclarados do paciente.
 * O disclaimer obrigatório (juridico/DISCLAIMER_MEDICO.md) é impresso no rodapé.
 */
const PDFDocument = require('pdfkit');
const { sha256 } = require('./crypto');

/**
 * @param {object} dados { paciente, perfil, logs, scores, streak }
 * @returns {Promise<Buffer>}
 */
function gerarRelatorio(dados) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50, info: { Title: 'Relatório Assistente de Caneta' } });
    const chunks = [];
    doc.on('data', (c) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const geradoEm = new Date().toISOString();

    // Cabeçalho
    doc.fontSize(18).text('Assistente de Caneta — Relatório de Acompanhamento', { align: 'center' });
    doc.moveDown(0.5);
    doc.fontSize(10).fillColor('#555')
      .text(`Paciente: ${dados.paciente.nome}  •  Gerado em: ${geradoEm}`, { align: 'center' });
    doc.moveDown(1);

    // Perfil
    doc.fillColor('#000').fontSize(13).text('Tratamento declarado pelo paciente');
    doc.fontSize(10).moveDown(0.3);
    const p = dados.perfil || {};
    doc.text(`Medicação: ${p.medicacao ? `${p.medicacao.nome} (${p.medicacao.principioAtivo})` : 'não informada'}`);
    doc.text(`Dose declarada: ${p.doseAtual || '—'}   Frequência: ${p.frequencia || p.medicacao?.frequenciaPadrao || '—'}`);
    doc.text(`Streak de registros: ${dados.streak ?? 0} dia(s) consecutivos`);
    doc.moveDown(1);

    // Logs
    doc.fontSize(13).text(`Registros diários (${dados.logs.length} dia(s))`);
    doc.moveDown(0.3).fontSize(9);
    doc.text('Data          Peso(kg)   Proteína(g)   Água(ml)   Dose   Observações', { continued: false });
    doc.moveTo(50, doc.y + 2).lineTo(545, doc.y + 2).stroke('#999');
    doc.moveDown(0.4);
    for (const log of dados.logs) {
      const linha = [
        String(log.data).slice(0, 10).padEnd(14),
        String(log.pesoKg ?? '—').padEnd(11),
        String(log.proteinaG ?? '—').padEnd(14),
        String(log.aguaMl ?? '—').padEnd(11),
        (log.doseAplicada ? 'sim' : 'não').padEnd(7),
        (log.efeitos || log.alimentos || '').slice(0, 40),
      ].join('');
      doc.text(linha);
      if (doc.y > 720) { doc.addPage(); doc.fontSize(9); }
    }
    doc.moveDown(1);

    // Scores
    if (dados.scores?.length) {
      doc.fontSize(13).text('Aderência ao plano de registro (últimas semanas)');
      doc.moveDown(0.3).fontSize(9);
      for (const s of dados.scores) {
        doc.text(`${s.data}: ${s.score}%`);
        if (doc.y > 720) { doc.addPage(); doc.fontSize(9); }
      }
    }

    // Disclaimer obrigatório + hash de integridade
    const hash = sha256(JSON.stringify({ logs: dados.logs, geradoEm })).slice(0, 16);
    doc.moveDown(1.5).fontSize(8).fillColor('#777').text(
      `Este relatório reúne dados AUTODECLARADOS pelo paciente no aplicativo Assistente de Caneta e destina-se a apoiar a consulta ` +
      `com o profissional de saúde. Não constitui laudo, diagnóstico ou documento clínico-legal. ` +
      `Gerado em ${geradoEm} — verificação de integridade: ${hash}.`,
      { align: 'justify' }
    );

    doc.end();
  });
}

module.exports = { gerarRelatorio };
