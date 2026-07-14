// Ambiente de teste — chaves fixas APENAS para testes unitários (nunca usar em produção)
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'segredo-de-teste-unitario';
process.env.DATA_ENCRYPTION_KEY = 'a'.repeat(64);
