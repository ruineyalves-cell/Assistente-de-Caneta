/**
 * Unit tests do módulo de pré-consulta (Lote 32.2).
 * Puramente lógica — não toca em DB nem crypto.
 */

const { calcularFatos, classificarImc, agregarSintomas } = require('../src/utils/preConsulta');
const { selecionarPerguntas } = require('../src/utils/perguntasPreConsulta');

function log(data, extra = {}) {
  return {
    data,
    pesoKg: null,
    proteinaG: null,
    aguaMl: null,
    alimentos: null,
    doseAplicada: false,
    efeitos: null,
    ...extra,
  };
}

function sintomasJson(...pares) {
  return JSON.stringify({
    sintomas: pares.map(([nome, intensidade]) => ({ nome, intensidade })),
  });
}

describe('classificarImc', () => {
  test('null quando altura desconhecida', () => {
    expect(classificarImc(80, null)).toBeNull();
    expect(classificarImc(null, 170)).toBeNull();
  });

  test('faixas OMS', () => {
    expect(classificarImc(50, 170).classe).toBe('baixo peso');
    expect(classificarImc(70, 170).classe).toBe('eutrofia');
    expect(classificarImc(80, 170).classe).toBe('sobrepeso');
    expect(classificarImc(90, 170).classe).toBe('obesidade grau I');
    expect(classificarImc(105, 170).classe).toBe('obesidade grau II');
    expect(classificarImc(120, 170).classe).toBe('obesidade grau III');
  });

  test('IMC arredondado 1 casa', () => {
    const r = classificarImc(80, 170);
    expect(r.imc).toBe(27.7);
  });
});

describe('agregarSintomas', () => {
  test('vazio quando não há efeitos', () => {
    expect(agregarSintomas([log('2026-07-01')])).toEqual([]);
  });

  test('ignora JSON inválido silenciosamente', () => {
    expect(agregarSintomas([log('2026-07-01', { efeitos: 'texto solto' })])).toEqual([]);
  });

  test('agrega ocorrências e retorna intensidade dominante', () => {
    const logs = [
      log('2026-07-01', { efeitos: sintomasJson(['Náusea', 'moderada']) }),
      log('2026-07-02', { efeitos: sintomasJson(['Náusea', 'moderada']) }),
      log('2026-07-03', { efeitos: sintomasJson(['Náusea', 'intensa'], ['Fadiga', 'leve']) }),
    ];
    const r = agregarSintomas(logs);
    expect(r[0].nome).toBe('Náusea');
    expect(r[0].ocorrencias).toBe(3);
    expect(r[0].intensidadeDominante).toBe('moderada');
    expect(r[1].nome).toBe('Fadiga');
    expect(r[1].ocorrencias).toBe(1);
  });
});

describe('calcularFatos', () => {
  test('paciente sem logs → tudo zerado / null', () => {
    const f = calcularFatos({ perfil: null, logs: [], janelaDias: 30 });
    expect(f.registros).toBe(0);
    expect(f.adesaoRegistroPct).toBe(0);
    expect(f.peso.atual).toBeNull();
    expect(f.peso.imc).toBeNull();
    expect(f.dose.adesaoPct).toBe(0);
    expect(f.topSintomas).toEqual([]);
  });

  test('perda de peso saudável ao longo de 30 dias', () => {
    const logs = [
      log('2026-06-20', { pesoKg: 100 }),
      log('2026-06-27', { pesoKg: 98.8 }),
      log('2026-07-04', { pesoKg: 97.6 }),
      log('2026-07-11', { pesoKg: 96.5 }),
    ];
    const f = calcularFatos({
      perfil: { alturaCm: 170, medicacao: { nome: 'Ozempic' } },
      logs,
      janelaDias: 30,
    });
    expect(f.peso.inicial).toBe(100);
    expect(f.peso.atual).toBe(96.5);
    expect(f.peso.variacaoKg).toBe(-3.5);
    expect(f.peso.kgPorSemana).toBeLessThan(-0.5);
    expect(f.peso.kgPorSemana).toBeGreaterThan(-1.5);
    // 96.5kg / (1.70m)² = 33.4 → obesidade grau I na tabela OMS
    expect(f.peso.classeOms).toBe('obesidade grau I');
    expect(f.medicacao).toBe('Ozempic');
  });

  test('adesão à dose 4 de 4 esperadas', () => {
    const logs = [
      log('2026-06-25', { doseAplicada: true }),
      log('2026-07-02', { doseAplicada: true }),
      log('2026-07-09', { doseAplicada: true }),
      log('2026-07-16', { doseAplicada: true }),
    ];
    const f = calcularFatos({ perfil: null, logs, janelaDias: 30 });
    expect(f.dose.aplicadas).toBe(4);
    expect(f.dose.esperadas).toBe(4);
    expect(f.dose.adesaoPct).toBe(100);
  });

  test('kg/semana só calcula com ≥14 dias entre pesagens', () => {
    const logs = [
      log('2026-07-10', { pesoKg: 90 }),
      log('2026-07-16', { pesoKg: 89 }),
    ];
    const f = calcularFatos({ perfil: null, logs, janelaDias: 30 });
    expect(f.peso.variacaoKg).toBe(-1);
    expect(f.peso.kgPorSemana).toBeNull();
  });
});

describe('selecionarPerguntas', () => {
  test('paciente com sintoma intenso persistente → pergunta específica prioriza', () => {
    const fatos = {
      janelaDias: 30,
      registros: 20,
      adesaoRegistroPct: 66,
      peso: {
        inicial: 95,
        atual: 93,
        variacaoKg: -2,
        kgPorSemana: -0.5,
        imc: 32.2,
        classeOms: 'obesidade grau I',
      },
      dose: { aplicadas: 4, esperadas: 4, adesaoPct: 100 },
      topSintomas: [
        { nome: 'Náusea', ocorrencias: 5, intensidadeDominante: 'intensa' },
      ],
      medicacao: 'Ozempic',
    };
    const perguntas = selecionarPerguntas(fatos, { limite: 5 });
    expect(perguntas[0].id).toBe('sintoma-intenso-persistente');
    expect(perguntas[0].texto).toContain('Náusea');
    expect(perguntas[0].referencia).toBe('Bula Anvisa');
  });

  test('paciente estagnado sem sintomas → pergunta de peso estagnado + base', () => {
    const fatos = {
      janelaDias: 30,
      registros: 25,
      adesaoRegistroPct: 83,
      peso: {
        inicial: 90,
        atual: 90.1,
        variacaoKg: 0.1,
        kgPorSemana: null,
        imc: 31.1,
        classeOms: 'obesidade grau I',
      },
      dose: { aplicadas: 4, esperadas: 4, adesaoPct: 100 },
      topSintomas: [],
      medicacao: 'Mounjaro',
    };
    const perguntas = selecionarPerguntas(fatos, { limite: 5 });
    const ids = perguntas.map((p) => p.id);
    expect(ids).toContain('peso-estagnado');
    // Preenche o resto com base (sem repetir)
    expect(new Set(ids).size).toBe(ids.length);
    expect(perguntas.length).toBeGreaterThanOrEqual(3);
  });

  test('paciente sem dados relevantes → 3 perguntas base', () => {
    const fatos = {
      janelaDias: 30,
      registros: 3,
      adesaoRegistroPct: 10,
      peso: { inicial: null, atual: null, variacaoKg: null, kgPorSemana: null, imc: null, classeOms: null },
      dose: { aplicadas: 0, esperadas: 4, adesaoPct: 0 },
      topSintomas: [],
      medicacao: null,
    };
    const perguntas = selecionarPerguntas(fatos, { limite: 5 });
    // Adesão baixa + registro baixo + 3 base
    expect(perguntas.length).toBeGreaterThanOrEqual(3);
    perguntas.forEach((p) => expect(p.texto.length).toBeGreaterThan(20));
  });

  test('limita a N perguntas', () => {
    const fatos = {
      janelaDias: 30,
      registros: 25,
      adesaoRegistroPct: 30,
      peso: {
        inicial: 100,
        atual: 92,
        variacaoKg: -8,
        kgPorSemana: -2,
        imc: 30.5,
        classeOms: 'obesidade grau I',
      },
      dose: { aplicadas: 4, esperadas: 4, adesaoPct: 100 },
      topSintomas: [
        { nome: 'Náusea', ocorrencias: 10, intensidadeDominante: 'intensa' },
        { nome: 'Fadiga', ocorrencias: 8, intensidadeDominante: 'moderada' },
        { nome: 'Refluxo', ocorrencias: 4, intensidadeDominante: 'leve' },
      ],
      medicacao: 'Mounjaro',
    };
    const perguntas = selecionarPerguntas(fatos, { limite: 3 });
    expect(perguntas.length).toBe(3);
  });
});
