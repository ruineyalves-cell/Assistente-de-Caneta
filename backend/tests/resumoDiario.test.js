/**
 * Unit tests do resumoDiario (Lote 32.3).
 */

const { calcularResumo, faixaHoraria } = require('../src/utils/resumoDiario');

const MANHA = new Date('2026-07-19T09:00:00-03:00');
const TARDE = new Date('2026-07-19T14:00:00-03:00');
const NOITE = new Date('2026-07-19T22:00:00-03:00');

describe('faixaHoraria', () => {
  test('manha: 5h-11h', () => {
    expect(faixaHoraria(new Date('2026-07-19T05:00:00'))).toBe('manha');
    expect(faixaHoraria(new Date('2026-07-19T11:59:00'))).toBe('manha');
  });
  test('tarde: 12h-17h', () => {
    expect(faixaHoraria(new Date('2026-07-19T12:00:00'))).toBe('tarde');
    expect(faixaHoraria(new Date('2026-07-19T17:59:00'))).toBe('tarde');
  });
  test('noite: 18h-4h', () => {
    expect(faixaHoraria(new Date('2026-07-19T18:00:00'))).toBe('noite');
    expect(faixaHoraria(new Date('2026-07-19T04:59:00'))).toBe('noite');
  });
});

describe('calcularResumo', () => {
  test('sem log E sem perfil → mensagem convite, vazio = true', () => {
    const r = calcularResumo({
      perfil: null,
      logHoje: null,
      agora: MANHA,
    });
    expect(r.vazio).toBe(true);
    expect(r.linhas).toHaveLength(1);
    expect(r.linhas[0].tipo).toBe('dica');
    expect(r.linhas[0].texto).toMatch(/registros/i);
    expect(r.saudacao).toBe('manha');
  });

  test('sem log mas com perfil → mostra meta de água pendente', () => {
    const r = calcularResumo({
      perfil: { pesoInicialKg: 80, metaAguaMlKg: 35 }, // meta 2,8L
      logHoje: null,
      agora: MANHA,
    });
    expect(r.vazio).toBe(false);
    const agua = r.linhas.find((l) => l.tipo === 'agua');
    expect(agua.texto).toMatch(/Faltam.*2,8 L/);
  });

  test('água registrada e meta batida', () => {
    const r = calcularResumo({
      perfil: { pesoInicialKg: 80, metaAguaMlKg: 35 },
      logHoje: { aguaMl: 3000 },
      agora: TARDE,
    });
    const agua = r.linhas.find((l) => l.tipo === 'agua');
    expect(agua).toBeTruthy();
    expect(agua.texto).toMatch(/batida/i);
    expect(agua.texto).toMatch(/3,0 L/);
    expect(r.vazio).toBe(false);
  });

  test('água abaixo da meta mostra faltante', () => {
    const r = calcularResumo({
      perfil: { pesoInicialKg: 100, metaAguaMlKg: 35 }, // meta 3.5L
      logHoje: { aguaMl: 1800 },
      agora: TARDE,
    });
    const agua = r.linhas.find((l) => l.tipo === 'agua');
    expect(agua.texto).toMatch(/Faltam/);
    expect(agua.texto).toMatch(/1,8 L/);
  });

  test('refeições contadas ignoram linha de peso', () => {
    const r = calcularResumo({
      perfil: { pesoInicialKg: 70 },
      logHoje: {
        alimentos: 'Frango grelhado\nArroz\nPeso: 69,5 kg @ Casa',
      },
      agora: NOITE,
    });
    const refeicao = r.linhas.find((l) => l.tipo === 'refeicao');
    // 2 refeições (não 3, porque a linha de peso é filtrada)
    expect(refeicao.texto).toMatch(/2 refeições/);
  });

  test('dose aplicada aparece', () => {
    const r = calcularResumo({
      perfil: null,
      logHoje: { doseAplicada: true },
      agora: MANHA,
    });
    const dose = r.linhas.find((l) => l.tipo === 'dose');
    expect(dose.texto).toBe('Dose aplicada hoje.');
  });

  test('sintoma intenso destaca nome', () => {
    const r = calcularResumo({
      perfil: null,
      logHoje: {
        efeitos: JSON.stringify({
          sintomas: [
            { nome: 'Náusea', intensidade: 'intensa' },
            { nome: 'Fadiga', intensidade: 'leve' },
          ],
        }),
      },
      agora: NOITE,
    });
    const s = r.linhas.find((l) => l.tipo === 'sintomas');
    expect(s.texto).toMatch(/intenso/i);
    expect(s.texto).toContain('Náusea');
  });

  test('nunca prescreve — verbo proibido', () => {
    const r = calcularResumo({
      perfil: { pesoInicialKg: 80, metaAguaMlKg: 35 },
      logHoje: { aguaMl: 3000, doseAplicada: true, pesoKg: 79.4 },
      agora: TARDE,
    });
    for (const l of r.linhas) {
      expect(l.texto).not.toMatch(/tome|pare|reduza|aumente|prescreva/i);
    }
  });

  test('proteína registrada e meta batida', () => {
    const r = calcularResumo({
      perfil: { pesoInicialKg: 70, metaProteinaGkg: 1.2 }, // meta 84g
      logHoje: { proteinaG: 100 },
      agora: TARDE,
    });
    const p = r.linhas.find((l) => l.tipo === 'refeicao' && /prote[ií]na/i.test(l.texto));
    expect(p).toBeTruthy();
    expect(p.texto).toMatch(/batida/i);
    expect(p.texto).toContain('100 g');
  });

  test('peso registrado hoje aparece com 1 decimal', () => {
    const r = calcularResumo({
      perfil: null,
      logHoje: { pesoKg: 87.234 },
      agora: TARDE,
    });
    const p = r.linhas.find((l) => l.tipo === 'peso');
    expect(p.texto).toContain('87,2');
  });
});
