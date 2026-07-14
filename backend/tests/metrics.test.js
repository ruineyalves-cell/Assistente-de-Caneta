const { calcularConformidadeDia, calcularStreak } = require('../src/utils/metrics');

describe('motor de conformidade (determinístico)', () => {
  test('dia perfeito = 100', () => {
    const r = calcularConformidadeDia({
      pesoKg: 100, proteinaG: 120, aguaMl: 3500, registrou: true,
    });
    expect(r.score).toBe(100);
    expect(r.componentes).toEqual({ proteina: 100, hidratacao: 100, registro: 100 });
    expect(r.alertas).toHaveLength(0);
  });

  test('proteína baixa gera alerta com fonte e rodapé', () => {
    const r = calcularConformidadeDia({
      pesoKg: 100, proteinaG: 50, aguaMl: 3500, registrou: true,
    });
    const alerta = r.alertas.find((a) => a.codigo === 'PROTEINA_BAIXA');
    expect(alerta).toBeDefined();
    expect(alerta.fonte).toContain('ABESO');
    expect(alerta.mensagem).toContain('Converse com seu médico');
    expect(alerta.rodape).toContain('Não é recomendação médica');
    expect(r.componentes.proteina).toBe(42); // 50 / 120 ≈ 42%
  });

  test('hidratação baixa gera alerta citando bula', () => {
    const r = calcularConformidadeDia({
      pesoKg: 80, proteinaG: 100, aguaMl: 1000, registrou: true,
    });
    const alerta = r.alertas.find((a) => a.codigo === 'HIDRATACAO_BAIXA');
    expect(alerta).toBeDefined();
    expect(alerta.fonte).toContain('Anvisa');
  });

  test('sem registro: score cai e gera alerta', () => {
    const r = calcularConformidadeDia({ pesoKg: null, proteinaG: null, aguaMl: null, registrou: false });
    expect(r.score).toBe(0);
    expect(r.alertas[0].codigo).toBe('SEM_REGISTRO');
  });

  test('componentes sem dado redistribuem peso (não penalizam)', () => {
    const r = calcularConformidadeDia({ pesoKg: 90, proteinaG: null, aguaMl: null, registrou: true });
    expect(r.componentes.proteina).toBeNull();
    expect(r.componentes.hidratacao).toBeNull();
    expect(r.score).toBe(100); // só o componente registro conta
  });

  test('metas personalizadas pelo profissional são respeitadas', () => {
    const r = calcularConformidadeDia({
      pesoKg: 100, proteinaG: 160, aguaMl: 3500, registrou: true, metaProteinaGkg: 1.6,
    });
    expect(r.componentes.proteina).toBe(100);
  });
});

describe('streak de registros', () => {
  test('conta dias consecutivos até hoje', () => {
    expect(calcularStreak(['2026-07-12', '2026-07-13', '2026-07-14'], '2026-07-14')).toBe(3);
  });

  test('hoje ainda sem registro conta a partir de ontem', () => {
    expect(calcularStreak(['2026-07-12', '2026-07-13'], '2026-07-14')).toBe(2);
  });

  test('quebra de sequência zera corretamente', () => {
    expect(calcularStreak(['2026-07-10', '2026-07-13'], '2026-07-14')).toBe(1);
  });

  test('sem registros = 0', () => {
    expect(calcularStreak([], '2026-07-14')).toBe(0);
  });
});
