const { encryptField, decryptField, decryptNumber } = require('../src/utils/crypto');

describe('crypto (AES-256-GCM)', () => {
  test('cifra e decifra texto', () => {
    const enc = encryptField('dado sensível de saúde çãé');
    expect(enc).not.toContain('dado sensível');
    expect(enc.split(':')).toHaveLength(3);
    expect(decryptField(enc)).toBe('dado sensível de saúde çãé');
  });

  test('cifra e decifra números', () => {
    const enc = encryptField(87.5);
    expect(decryptNumber(enc)).toBe(87.5);
  });

  test('valores nulos/vazios viram null', () => {
    expect(encryptField(null)).toBeNull();
    expect(encryptField('')).toBeNull();
    expect(decryptField(null)).toBeNull();
  });

  test('mesmo valor gera ciphertext diferente (IV aleatório)', () => {
    expect(encryptField('87.5')).not.toBe(encryptField('87.5'));
  });

  test('ciphertext adulterado falha (authTag GCM)', () => {
    const enc = encryptField('original');
    const [iv, tag, data] = enc.split(':');
    const corrompido = `${iv}:${tag}:${Buffer.from('xxxxxx').toString('base64')}`;
    expect(() => decryptField(corrompido)).toThrow();
    void data;
  });
});
