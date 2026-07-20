/**
 * Unit tests dos normalizadores do iaController (Lote 32.8).
 */
const {
  _normalizarRotulo,
  _normalizarBula,
  _normalizarRefeicao,
  _parseJsonSeguro,
} = require('../src/controllers/iaController');

describe('_normalizarRefeicao', () => {
  test('valor completo passa como recebido', () => {
    const r = _normalizarRefeicao({
      titulo: 'Frango grelhado',
      descricao: 'Frango + arroz + salada',
      proteinaEstimadaG: 42,
      aguaEstimadaMl: 300,
      confianca: 0.82,
    });
    expect(r.titulo).toBe('Frango grelhado');
    expect(r.proteinaEstimadaG).toBe(42);
    expect(r.confianca).toBe(0.82);
  });

  test('arredonda proteína e água', () => {
    const r = _normalizarRefeicao({
      proteinaEstimadaG: 42.7,
      aguaEstimadaMl: 299.3,
    });
    expect(r.proteinaEstimadaG).toBe(43);
    expect(r.aguaEstimadaMl).toBe(299);
  });

  test('campos ausentes → null e confianca 0.5', () => {
    const r = _normalizarRefeicao({});
    expect(r.titulo).toBeNull();
    expect(r.proteinaEstimadaG).toBeNull();
    expect(r.confianca).toBe(0.5);
  });
});

describe('_normalizarRotulo', () => {
  test('macros completos', () => {
    const r = _normalizarRotulo({
      produto: 'Aveia em flocos',
      porcao: '30 g',
      caloriasKcal: 120,
      proteinaG: 4.5,
      carboidratosG: 20,
      gordurasG: 2,
      gordurasSaturadasG: 0.5,
      fibraG: 3.5,
      sodioMg: 10,
      confianca: 0.9,
    });
    expect(r.produto).toBe('Aveia em flocos');
    expect(r.porcao).toBe('30 g');
    expect(r.proteinaG).toBe(4.5);
    expect(r.sodioMg).toBe(10);
    expect(r.confianca).toBe(0.9);
  });

  test('null quando IA não conseguiu ler o rótulo', () => {
    const r = _normalizarRotulo({ produto: null, confianca: 0.0 });
    expect(r.produto).toBeNull();
    expect(r.caloriasKcal).toBeNull();
    expect(r.confianca).toBe(0.0);
  });

  test('valor não-numérico vira null (defesa contra IA maluca)', () => {
    const r = _normalizarRotulo({
      caloriasKcal: 'muitas',
      proteinaG: null,
      gordurasG: NaN,
    });
    expect(r.caloriasKcal).toBeNull();
    expect(r.proteinaG).toBeNull();
    expect(r.gordurasG).toBeNull();
  });
});

describe('_normalizarBula', () => {
  test('bula bem lida com listas', () => {
    const r = _normalizarBula({
      medicamento: 'Ozempic',
      principioAtivo: 'Semaglutida',
      indicacoes: ['Diabetes tipo 2', 'Obesidade'],
      dose: '0,25 mg semanal',
      efeitosComuns: ['Náusea', 'Refluxo'],
      alertas: ['Não usar em gestantes'],
      confianca: 0.88,
    });
    expect(r.medicamento).toBe('Ozempic');
    expect(r.indicacoes).toHaveLength(2);
    expect(r.efeitosComuns[0]).toBe('Náusea');
    expect(r.alertas).toHaveLength(1);
  });

  test('listas sujas são filtradas', () => {
    const r = _normalizarBula({
      indicacoes: ['Válido', '', null, 42, 'Outro'],
      efeitosComuns: null,
      alertas: undefined,
    });
    expect(r.indicacoes).toEqual(['Válido', 'Outro']);
    expect(r.efeitosComuns).toEqual([]);
    expect(r.alertas).toEqual([]);
  });

  test('bula ilegível: tudo null/vazio', () => {
    const r = _normalizarBula({});
    expect(r.medicamento).toBeNull();
    expect(r.indicacoes).toEqual([]);
    expect(r.efeitosComuns).toEqual([]);
    expect(r.confianca).toBe(0.5);
  });
});

describe('_parseJsonSeguro', () => {
  test('parse direto', () => {
    expect(_parseJsonSeguro('{"a":1}')).toEqual({ a: 1 });
  });

  test('recupera JSON envolto em texto', () => {
    const t = 'Aqui vai o JSON:\n{"a":2}\nfim.';
    expect(_parseJsonSeguro(t)).toEqual({ a: 2 });
  });

  test('JSON quebrado → {}', () => {
    expect(_parseJsonSeguro('não é json')).toEqual({});
  });
});
