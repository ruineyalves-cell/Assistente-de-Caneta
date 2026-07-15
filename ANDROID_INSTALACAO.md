# 📱 Instalação no Android - Guia Completo

**Status:** ✅ APK gerado automaticamente via GitHub Actions

---

## 🎯 Requisitos

- ✅ Android 6.0+ (API Level 21+)
- ✅ ~50 MB de espaço livre
- ✅ Conexão com internet para login
- ⚠️ Permissão para instalar "Aplicativos de fontes desconhecidas"

---

## 📥 OPÇÃO 1: Baixar APK (Recomendado)

### **Passo 1: Acessar GitHub Actions**

1. Acesse: https://github.com/seu-username/Assistente-de-Caneta
2. Clique em **"Actions"** (na barra superior)
3. Procure o workflow: **"Build Android APK"**
4. Clique na última execução (mais recente)

### **Passo 2: Download do APK**

1. Role para baixo até **"Artifacts"**
2. Clique em **"android-apk"**
3. Vai fazer download de um ZIP
4. Descompacte e obtenha: `flutter-app-release.apk`

### **Passo 3: Transferir para Celular**

**Via USB (Recomendado):**
```
1. Conectar celular ao PC via USB
2. Ativar "Transferência de arquivos" no celular
3. Copiar APK para pasta do celular (ex: Downloads)
4. Desconectar USB
```

**Via Google Drive:**
```
1. Fazer upload do APK para Google Drive
2. Abrir Google Drive no celular
3. Clicar em "Baixar" no arquivo
4. APK vai para Downloads
```

**Via Bluetooth:**
```
1. Enviar APK via Bluetooth do PC para celular
2. Arquivo vai para Downloads
```

---

## 📱 INSTALAÇÃO NO CELULAR

### **Passo 1: Preparar Celular**

1. Abrir **Configurações** → **Segurança**
2. Procurar **"Fontes desconhecidas"** ou **"Instalar aplicativos desconhecidos"**
3. ✅ **ATIVAR** para a app "Gerenciador de Arquivos"
   - (Isso permite instalar APKs de fontes não-Google Play)

### **Passo 2: Instalar APK**

1. Abrir **Gerenciador de Arquivos** ou **Files**
2. Navegar para **Downloads**
3. Procurar **`flutter-app-release.apk`**
4. 👉 **Tocar no arquivo**
5. Clicar em **"Instalar"**
6. Aguardar conclusão (15-30 segundos)
7. ✅ Clicar em **"Abrir"** ou **"Concluído"**

---

## 🚀 PRIMEIRO USO

### **Na Primeira Execução:**

1. **Lê Termos de Uso** (obrigatório)
2. **LGPD Disclaimer** - Confirma consentimento
3. **Cria Conta:**
   - Email
   - Senha (8+ caracteres)
   - Data de nascimento (18+)
   - Peso (kg), Altura (cm)

### **Depois:**

- ✅ Dashboard com score de conformidade
- ✅ Registrar dose diária
- ✅ Ver histórico de 28 dias
- ✅ Acompanhar seu perfil

---

## ⚡ PERMISSÕES NECESSÁRIAS

O app pede:

- ✅ **Internet** - Conectar ao backend
- ✅ **Câmera** (opcional) - OCR de receita
- ⚠️ Aceite as permissões quando solicitado

---

## 🐛 TROUBLESHOOTING

### **"Não é possível instalar"**
```
Solução 1: Ir em Configurações → Aplicativos → Gerenciador de Arquivos
           → Permissões → Ativar "Instalar aplicativos desconhecidos"

Solução 2: Deletar versão antiga se existir
           Configurações → Aplicativos → Assistente de Caneta → Desinstalar

Solução 3: Reiniciar celular e tentar novamente
```

### **"App fecha logo após abrir"**
```
Solução 1: Verificar conexão com internet (WiFi ou dados)
Solução 2: Forçar parada: Configurações → Aplicativos → Assistente de Caneta
           → Força parada → Abrir novamente
Solução 3: Limpar cache: Configurações → Aplicativos → Assistente de Caneta
           → Armazenamento → Limpar cache → Abrir novamente
```

### **"Não consegue conectar ao servidor"**
```
Solução 1: Verificar WiFi/dados móveis está ativado
Solução 2: Testar conexão de internet (abrir navegador)
Solução 3: Reiniciar WiFi/dados móveis
Solução 4: O backend pode estar em manutenção (verificar com dev)
```

### **"Erro de login"**
```
Solução 1: Verificar email e senha
Solução 2: Verificar data de nascimento (deve ser 18+)
Solução 3: Fazer novo registro se esquecer senha
```

---

## 🔄 ATUALIZAR APP

Toda vez que há novo código no GitHub:

1. GitHub Actions compila novo APK automaticamente
2. Descarregar novo APK (mesmo processo acima)
3. ⚠️ Antes de instalar, desinstalar versão antiga:
   - Configurações → Aplicativos → Assistente de Caneta → Desinstalar
4. Instalar novo APK

---

## 📊 VERIFICAR VERSÃO INSTALADA

```
Configurações → Aplicativos → Assistente de Caneta → Informações

Mostra:
- Versão: 0.1.0
- Tamanho: ~45 MB
- Data de instalação
```

---

## ✅ CHECKLIST DE INSTALAÇÃO

- [ ] Celular Android 6.0+
- [ ] APK baixado (do GitHub Actions)
- [ ] Permissão "Fontes desconhecidas" ativada
- [ ] APK transferido para Downloads
- [ ] App instalado com sucesso
- [ ] App abre sem erros
- [ ] Internet funcionando
- [ ] Consegue fazer login
- [ ] Dashboard carrega

---

## 🆘 PRECISA DE AJUDA?

Se tiver problemas:
1. Tentar as soluções em "Troubleshooting"
2. Enviar screenshot do erro
3. Descrever o que aconteceu
4. Descrever seu celular (modelo, Android version)

---

## 📞 INFO TÉCNICA

- **Package Name:** `com.example.assistente_caneta`
- **API Mínima:** Android 6.0 (API 21)
- **API Alvo:** Android 14 (API 34)
- **Arquitetura:** arm64-v8a, armeabi-v7a
- **Tamanho APK:** ~45 MB
- **Backend:** `https://assistente-caneta-backend.onrender.com`

---

**Pronto? Baixa o APK e instala! 🚀**
