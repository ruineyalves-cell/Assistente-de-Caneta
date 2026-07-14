/**
 * Mock de banco de dados em-memória (sem dependências)
 * Para testes rápidos da API sem PostgreSQL/SQLite
 * Suporta operações INSERT, SELECT, UPDATE de forma simplificada
 */

const data = {
  users: [],
  medications: [],
  patient_profiles: [],
  daily_logs: [],
  refresh_tokens: [],
  consents: [],
  audit_logs: [],
  compliance_scores: [],
  patient_professional_links: [],
};

// Medicações padrão (seed básico)
const MEDICATIONS_SEED = [
  { id: 1, nome_comercial: 'Mounjaro', principio_ativo: 'Tirzepatida', fabricante: 'Eli Lilly', status_anvisa: 'aprovado', categoria: 'GLP-1/GIP', indicacoes: 'Diabetes tipo 2; obesidade', frequencia_padrao: '1x/semana', via: 'subcutanea', doses_disponiveis: ['2.5mg','5mg','7.5mg','10mg','12.5mg','15mg'], preco_referencia: {}, receituario: 'Receita retida', bula_url: null, ativo: true },
  { id: 2, nome_comercial: 'Ozempic', principio_ativo: 'Semaglutida', fabricante: 'Novo Nordisk', status_anvisa: 'aprovado', categoria: 'GLP-1', indicacoes: 'Diabetes tipo 2', frequencia_padrao: '1x/semana', via: 'subcutanea', doses_disponiveis: ['0.25mg','0.5mg','1mg','2mg'], preco_referencia: {}, receituario: 'Receita retida', bula_url: null, ativo: true },
  { id: 3, nome_comercial: 'Wegovy', principio_ativo: 'Semaglutida', fabricante: 'Novo Nordisk', status_anvisa: 'aprovado', categoria: 'GLP-1', indicacoes: 'Obesidade', frequencia_padrao: '1x/semana', via: 'subcutanea', doses_disponiveis: ['0.25mg','0.5mg','1mg','1.7mg','2.4mg'], preco_referencia: {}, receituario: 'Receita retida', bula_url: null, ativo: true },
  { id: 4, nome_comercial: 'Saxenda', principio_ativo: 'Liraglutida', fabricante: 'Novo Nordisk', status_anvisa: 'aprovado', categoria: 'GLP-1', indicacoes: 'Obesidade', frequencia_padrao: '1x/dia', via: 'subcutanea', doses_disponiveis: ['0.6mg','1.2mg','1.8mg','2.4mg','3.0mg'], preco_referencia: {}, receituario: 'Receita retida', bula_url: null, ativo: true },
];

data.medications = MEDICATIONS_SEED;

// UUID simples
const { randomUUID } = require('node:crypto');
function uuid() { return randomUUID(); }

// Parser SQL muito simples
function query(sql, params = []) {
  sql = sql.trim();
  params = params || [];

  // INSERT INTO
  if (sql.startsWith('INSERT INTO')) {
    const match = sql.match(/INSERT INTO (\w+)/i);
    const table = match ? match[1] : null;
    if (table && data[table]) {
      const row = {};
      // Extrai colunas do INSERT
      const colsMatch = sql.match(/\(([\w_,\s]+)\)\s*VALUES/i);
      if (colsMatch) {
        const colArray = colsMatch[1].split(',').map(c => c.trim());
        colArray.forEach((col, i) => {
          if (params[i] !== undefined) {
            row[col] = params[i];
          }
        });
      }
      // Gera ID se not found e se a coluna exista no schema
      if (!row.id && table === 'users') row.id = uuid();
      if (!row.id && table === 'patient_professional_links') row.id = uuid();
      // Timestamp
      if (!row.created_at && ['users', 'consents', 'audit_logs', 'refresh_tokens'].includes(table)) {
        row.created_at = new Date().toISOString();
      }
      if (!row.updated_at && ['medications', 'patient_profiles', 'daily_logs'].includes(table)) {
        row.updated_at = new Date().toISOString();
      }
      data[table].push(row);
      return Promise.resolve({ rows: [row], rowCount: 1 });
    }
  }

  // SELECT
  if (sql.startsWith('SELECT')) {
    let table = null;
    const match = sql.match(/FROM\s+(\w+)/i);
    if (match) table = match[1];

    let rows = table && data[table] ? JSON.parse(JSON.stringify(data[table])) : [];

    // WHERE clause simples ($1 syntax)
    if (sql.includes('WHERE')) {
      const whereMatch = sql.match(/WHERE\s+([\s\S]*?)(?:ORDER|LIMIT|$)/i);
      if (whereMatch) {
        const condition = whereMatch[1].trim();
        // Muito básico: id = $1, email = $1, user_id = $1, etc
        const condParts = condition.split(/\s+(AND|OR)\s+/i);
        rows = rows.filter(row => {
          let result = true;
          for (let i = 0; i < condParts.length; i += 2) {
            const cond = condParts[i];
            if (cond.includes('=') && cond.includes('$')) {
              const [col, paramIdx] = cond.split('=').map(s => s.trim());
              const idx = parseInt(paramIdx.replace('$', '')) - 1;
              if (idx >= 0 && params[idx] !== undefined) {
                const colName = col.replace(/[\w.]+\.(\w+)/, '$1');
                result = row[colName] === params[idx];
              }
            }
          }
          return result;
        });
      }
    }

    // LIMIT
    const limitMatch = sql.match(/LIMIT\s+(\d+)/i);
    if (limitMatch) rows = rows.slice(0, parseInt(limitMatch[1]));

    return Promise.resolve({ rows, rowCount: rows.length });
  }

  // UPDATE
  if (sql.startsWith('UPDATE')) {
    const match = sql.match(/UPDATE\s+(\w+)/i);
    const table = match ? match[1] : null;
    if (table && data[table]) {
      // Muito simples: UPDATE users SET role = $1 WHERE id = $2
      let updated = 0;
      data[table].forEach(row => {
        const idMatch = sql.match(/WHERE\s+id\s*=\s*\$(\d+)/i);
        if (idMatch) {
          const idx = parseInt(idMatch[1]) - 1;
          if (params[idx] && row.id === params[idx]) {
            // Extrai SET clause
            const setMatch = sql.match(/SET\s+([\s\S]*?)\s+WHERE/i);
            if (setMatch) {
              const setParts = setMatch[1].split(',').map(s => s.trim());
              let paramCount = 0;
              setParts.forEach(setPart => {
                const [col] = setPart.split('=').map(s => s.trim());
                if (col && params[paramCount] !== undefined) {
                  row[col] = params[paramCount];
                  paramCount++;
                }
              });
            }
            updated++;
          }
        }
      });
      return Promise.resolve({ rows: [], rowCount: updated });
    }
  }

  // DELETE
  if (sql.startsWith('DELETE')) {
    const match = sql.match(/FROM\s+(\w+)/i);
    const table = match ? match[1] : null;
    if (table && data[table]) {
      const before = data[table].length;
      // WHERE id = $1
      const idMatch = sql.match(/WHERE\s+id\s*=\s*\$(\d+)/i);
      if (idMatch) {
        const idx = parseInt(idMatch[1]) - 1;
        data[table] = data[table].filter(row => row.id !== params[idx]);
      }
      return Promise.resolve({ rows: [], rowCount: before - data[table].length });
    }
  }

  return Promise.resolve({ rows: [], rowCount: 0 });
}

console.log('✅ Mock DB em-memória carregado (4 medicações pré-carregadas)');
console.log('⚠️  Dados resetam a cada restart. Para persistência: instale PostgreSQL/Docker.');

module.exports = { query, pool: { end: () => Promise.resolve() } };
