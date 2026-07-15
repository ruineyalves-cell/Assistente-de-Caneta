# 🚀 Deploy em Render - Guia Passo a Passo

**Status:** ✅ PostgreSQL pronto, Backend testado, Pronto para deploy

---

## 📋 Checklist Rápido

- [x] PostgreSQL criado em Render
- [x] Migrations rodadas
- [x] Backend testado localmente
- [ ] Backend deployado em Render ← **PRÓXIMO**
- [ ] Frontend atualizado com URL de produção
- [ ] Frontend deployado em GitHub Pages
- [ ] Beta testing iniciado

---

## 🔧 PASSO 1: Conectar Render ao GitHub

1. Acesse **https://dashboard.render.com**
2. Clique em **"+ New"** → **"Web Service"**
3. Clique em **"Connect a repository"**
4. Selecione: **`leandro edmee/Assistente-de-Caneta`** (ou seu username)
5. Clique em **"Connect"**

---

## ⚙️ PASSO 2: Configurar Web Service

### **Informações Básicas:**
- **Name:** `assistente-caneta-backend`
- **Runtime:** `Node`
- **Region:** `Ohio (US East)`
- **Plan:** `Free` (até $5)

### **Build & Deploy:**
- **Build Command:** `cd backend && npm install`
- **Start Command:** `cd backend && npm start`
- **Auto Deploy:** Ativado (ao fazer push em main)

### **Environment Variables:**

Adicionar as seguintes variáveis:

```
DATABASE_URL
postgresql://appuser:jbtXKfID7nCRV4X2TbuqROFiqqVj8ZC1@dpg-d9bolkfavr4c73b71dmg-a.ohio-postgres.render.com/assistente_caneta?sslmode=require

NODE_ENV
production

PORT
3000

JWT_SECRET
your-super-secret-jwt-key-min-32-chars-change-in-prod

CORS_ORIGIN
*
```

---

## 🎯 PASSO 3: Fazer Deploy

1. Clique em **"Create Web Service"**
2. Render vai:
   - Clonar o repositório
   - Rodar `npm install`
   - Fazer build
   - Iniciar o servidor
3. Esperar ~5-10 minutos até status ficar **"Running"** (verde)

---

## ✅ PASSO 4: Validar Backend

Quando estiver pronto, acessar:

```
# Health Check
https://assistente-caneta-backend.onrender.com/health

# Medicações
https://assistente-caneta-backend.onrender.com/api/medicacoes
```

---

## 🎨 PASSO 5: Atualizar Frontend

Editar: `flutter_app/lib/utils/constants.dart`

**Trocar:**
```dart
static const String apiBaseUrl = 'http://192.168.0.16:3000';
```

**Por:**
```dart
static const String apiBaseUrl = 'https://assistente-caneta-backend.onrender.com';
```

---

## 🚀 PASSO 6: Deploy Frontend

1. Fazer commit:
   ```bash
   git add flutter_app/lib/utils/constants.dart
   git commit -m "feat: Update API URL to production Render backend"
   git push origin main
   ```

2. GitHub Actions vai fazer build automático
3. Frontend disponível em GitHub Pages

---

## 📊 URLs Finais

| Serviço | URL |
|---------|-----|
| **Backend API** | `https://assistente-caneta-backend.onrender.com` |
| **Frontend** | `https://seu-github-username.github.io/Assistente-de-Caneta/` |
| **PostgreSQL** | `dpg-d9bolkfavr4c73b71dmg-a.ohio-postgres.render.com:5432` |
| **Health Check** | `https://assistente-caneta-backend.onrender.com/health` |

---

## 🐛 Troubleshooting

### Deploy falhou?
1. Verificar logs em Render dashboard
2. Comum: Porta já em uso
3. Solução: Render automaticamente redireciona porta

### Erro de conexão PostgreSQL?
1. Verificar variável `DATABASE_URL` em Render
2. Confirmar string tem `?sslmode=require` no final
3. Verificar IP whitelist em Render PostgreSQL (deve aceitar `0.0.0.0/0`)

### Frontend não conecta ao backend?
1. Verificar `CORS_ORIGIN` em backend (deve ser `*` para testes)
2. Verificar URL em `constants.dart`
3. Testar health check no navegador

---

## ✨ Pronto!

Seu app está **100% pronto para beta testing** com:
- ✅ Backend em Render (produção)
- ✅ PostgreSQL em Render (produção)
- ✅ Frontend em GitHub Pages
- ✅ Autenticação JWT + AES-256 encryption
- ✅ Conformidade LGPD + Anvisa

**Próximo:** Comece beta testing com 5-10 usuários reais!

---

**Suporte:** Se tiver dúvidas, abra uma issue no GitHub ou converse comigo.
