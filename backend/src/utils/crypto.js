/**
 * Criptografia de dados de saúde em repouso — AES-256-GCM (LGPD art. 46).
 * Formato armazenado: base64(iv):base64(authTag):base64(ciphertext)
 * A chave (DATA_ENCRYPTION_KEY) tem 32 bytes em hex e NUNCA vai para o banco.
 */
const crypto = require('node:crypto');

const ALGO = 'aes-256-gcm';
const IV_BYTES = 12;

function getKey() {
  const raw = process.env.DATA_ENCRYPTION_KEY;
  if (!raw) {
    throw new Error('DATA_ENCRYPTION_KEY ausente. Configure a variável de ambiente.');
  }
  // Aceita uma chave hex de 32 bytes (64 chars) diretamente; caso contrário,
  // deriva deterministicamente 32 bytes via SHA-256 de qualquer segredo
  // (permite que o provedor gere o valor sem exigir formato hex específico).
  if (/^[0-9a-fA-F]{64}$/.test(raw)) return Buffer.from(raw, 'hex');
  return crypto.createHash('sha256').update(raw).digest();
}

function encryptField(plaintext) {
  if (plaintext === null || plaintext === undefined || plaintext === '') return null;
  const iv = crypto.randomBytes(IV_BYTES);
  const cipher = crypto.createCipheriv(ALGO, getKey(), iv);
  const enc = Buffer.concat([cipher.update(String(plaintext), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('base64')}:${tag.toString('base64')}:${enc.toString('base64')}`;
}

function decryptField(stored) {
  if (stored === null || stored === undefined || stored === '') return null;
  const [ivB64, tagB64, dataB64] = stored.split(':');
  if (!ivB64 || !tagB64 || !dataB64) throw new Error('Formato de campo criptografado inválido');
  const decipher = crypto.createDecipheriv(ALGO, getKey(), Buffer.from(ivB64, 'base64'));
  decipher.setAuthTag(Buffer.from(tagB64, 'base64'));
  const dec = Buffer.concat([decipher.update(Buffer.from(dataB64, 'base64')), decipher.final()]);
  return dec.toString('utf8');
}

/** Número criptografado → número em claro (ou null). */
function decryptNumber(stored) {
  const v = decryptField(stored);
  if (v === null) return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

module.exports = { encryptField, decryptField, decryptNumber, sha256 };
