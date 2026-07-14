/** Gera chaves fortes para o .env — copie e cole os valores. */
const crypto = require('node:crypto');

console.log('Copie para o seu .env:\n');
console.log(`JWT_SECRET=${crypto.randomBytes(48).toString('base64url')}`);
console.log(`DATA_ENCRYPTION_KEY=${crypto.randomBytes(32).toString('hex')}`);
console.log('\n⚠️ Em produção use chaves DIFERENTES das de desenvolvimento.');
console.log('⚠️ Se a DATA_ENCRYPTION_KEY for perdida, os dados criptografados são IRRECUPERÁVEIS — guarde em cofre (ex.: variáveis do Railway + backup seguro).');
