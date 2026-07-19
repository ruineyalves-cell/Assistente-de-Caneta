/**
 * Unit tests do detector de alertas (Lote 32.4).
 */

const {
  detectarSintomasPersistentes,
  calcularAlertas,
} = require('../src/utils/alertas');

const HOJE = new Date('2026-07-19T12:00:00Z');
function diaAtras(n) {
  return new Date(HOJE.getTime() - n * 86_400_000).toISOString().slice(0, 10);
}

function log(data, sintomas) {
  return {
    data,
    pesoKg: null,
    proteinaG: null,
    aguaMl: null,
    alimentos: null,
    doseAplicada: false,
    efeitos: JSON.stringify({ sintomas }),
  };
}

// Congela "agora" para o detector
beforeAll(() => {
  jest.useFakeTimers().setSystemTime(HOJE);
});
afterAll(() => {
  jest.useRealTimers();
});

describe('detectarSintomasPersistentes', () => {
  test('vazio quando não há logs', () => {
    expect(detectarSintomasPersistentes([])).toEqual([]);
  });

  test('sintoma moderado em 3 dias NÃO é persistente (só intenso conta)', () => {
    const logs = [
      log(diaAtras(1), [{ nome: 'Náusea', intensidade: 'moderada' }]),
      log(diaAtras(2), [{ nome: 'Náusea', intensidade: 'moderada' }]),
      log(diaAtras(3), [{ nome: 'Náusea', intensidade: 'moderada' }]),
    ];
    expect(detectarSintomasPersistentes(logs)).toEqual([]);
  });

  test('sintoma intenso em 3 dias distintos → persistente', () => {
    const logs = [
      log(diaAtras(1), [{ nome: 'Náusea', intensidade: 'intensa' }]),
      log(diaAtras(2), [{ nome: 'Náusea', intensidade: 'intensa' }]),
      log(diaAtras(4), [{ nome: 'Náusea', intensidade: 'intensa' }]),
    ];
    const r = detectarSintomasPersistentes(logs);
    expect(r).toHaveLength(1);
    expect(r[0].nome).toBe('Náusea');
    expect(r[0].diasIntensos).toBe(3);
  });

  test('registros duplicados no mesmo dia contam como 1 dia', () => {
    const logs = [
      log(diaAtras(1), [
        { nome: 'Fadiga', intensidade: 'intensa' },
        { nome: 'Fadiga', intensidade: 'intensa' },
      ]),
      log(diaAtras(2), [{ nome: 'Fadiga', intensidade: 'intensa' }]),
    ];
    const r = detectarSintomasPersistentes(logs);
    expect(r).toEqual([]);
  });

  test('ignora logs fora da janela de 7 dias', () => {
    const logs = [
      log(diaAtras(1), [{ nome: 'Náusea', intensidade: 'intensa' }]),
      log(diaAtras(2), [{ nome: 'Náusea', intensidade: 'intensa' }]),
      log(diaAtras(10), [{ nome: 'Náusea', intensidade: 'intensa' }]),
    ];
    expect(detectarSintomasPersistentes(logs)).toEqual([]);
  });

  test('múltiplos sintomas persistentes ordenados por dias', () => {
    const logs = [
      log(diaAtras(1), [
        { nome: 'Náusea', intensidade: 'intensa' },
        { nome: 'Refluxo', intensidade: 'intensa' },
      ]),
      log(diaAtras(2), [
        { nome: 'Náusea', intensidade: 'intensa' },
        { nome: 'Refluxo', intensidade: 'intensa' },
      ]),
      log(diaAtras(3), [
        { nome: 'Náusea', intensidade: 'intensa' },
        { nome: 'Refluxo', intensidade: 'intensa' },
      ]),
      log(diaAtras(4), [{ nome: 'Náusea', intensidade: 'intensa' }]),
    ];
    const r = detectarSintomasPersistentes(logs);
    expect(r.map((s) => s.nome)).toEqual(['Náusea', 'Refluxo']);
  });
});

describe('calcularAlertas', () => {
  test('sem sintomas persistentes → array vazio', () => {
    expect(calcularAlertas([])).toEqual([]);
  });

  test('sintoma intenso 3 dias → 1 alerta bem formado', () => {
    const logs = [
      log(diaAtras(1), [{ nome: 'Náusea', intensidade: 'intensa' }]),
      log(diaAtras(2), [{ nome: 'Náusea', intensidade: 'intensa' }]),
      log(diaAtras(3), [{ nome: 'Náusea', intensidade: 'intensa' }]),
    ];
    const [a] = calcularAlertas(logs);
    expect(a.tipo).toBe('sintoma-persistente');
    expect(a.severidade).toBe('importante');
    expect(a.titulo).toContain('Náusea');
    expect(a.descricao).toMatch(/3.*dias/);
    // Não pode prescrever nem diagnosticar
    expect(a.descricao).not.toMatch(/tome|pare|reduza|aumente|prescreva/i);
    expect(a.dados.sintoma).toBe('Náusea');
  });
});
