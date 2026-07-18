# Configurar Login com Google (passo a passo)

> Estas são as ações que **você precisa fazer manualmente** — envolvem contas Google suas, senhas suas e uma chave (SHA-1) da sua keystore. Eu (Claude) posso te ajudar em cada passo, mas não posso executar por você. Cada passo demora ~5 minutos.

---

## Pré-requisito: conta Google que vai ser dona do projeto

Use a mesma conta Google que vai administrar o Play Console. Se ainda não sabe qual, pense antes — não é fácil migrar depois.

**Dica:** crie uma conta `recorpo.app@gmail.com` só para o produto e evite misturar com sua conta pessoal.

---

## Passo 1 — Criar projeto Firebase (grátis)

1. Vá para https://console.firebase.google.com
2. Clique em **"Adicionar projeto"**
3. Nome do projeto: `Recorpo` (o Firebase vai gerar um ID como `recorpo-a1b2c`)
4. Google Analytics: **desative** por enquanto (não precisamos disso agora, dá pra ligar depois)
5. Confirme criação — leva ~1 minuto

---

## Passo 2 — Adicionar o app Android ao Firebase

1. Dentro do projeto, clique no ícone do Android
2. Preencha:
   - **Nome do pacote Android:** `br.com.recorpo.app`
   - **Apelido do app:** Recorpo
   - **SHA-1 (debug):** *(veja Passo 3 abaixo)*
3. Baixe o arquivo `google-services.json`
4. **Coloque o arquivo em** `flutter_app/android/app/google-services.json`

⚠️ Esse arquivo **não** vai pro GitHub (já está no `.gitignore` como boa prática). Faça backup em local seguro.

---

## Passo 3 — Gerar o SHA-1 da keystore de debug

Cole no terminal PowerShell (na raiz do repo):

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copie a linha que começa com `SHA1:` (é o dedo digital da sua máquina).

Cole no campo SHA-1 do Firebase (Passo 2).

Depois, quando gerar a **release keystore** própria (semana 1 do plano), rode o mesmo comando apontando pra ela e adicione **também** ao Firebase (dá pra ter várias SHA-1).

---

## Passo 4 — Habilitar Google como provedor de autenticação

1. No Firebase Console → menu esquerdo → **Authentication** → **Sign-in method**
2. Clique em **Google** → **Enable** → informe email de suporte (sua conta)
3. Salvar

O Firebase vai gerar 2 Client IDs no Google Cloud Console:
- **Web client ID** (ex: `123456789-abc.apps.googleusercontent.com`) — este é o que o Flutter usa como `aud` do idToken
- **Android client ID** (com o SHA-1 do passo anterior)

---

## Passo 5 — Pegar o Web Client ID

1. Vá para https://console.cloud.google.com
2. Selecione o projeto que o Firebase criou
3. Menu → **APIs & Services** → **Credentials**
4. Copie o **Client ID** cujo tipo é **"Web application"** (o único, provavelmente chamado "Web client (auto created by Google Service)")

---

## Passo 6 — Configurar o backend com esse Client ID

No painel do **Render** (backend):

1. Abra o serviço `assistente-caneta-backend`
2. **Environment** → **Add Environment Variable**
3. Nome: `GOOGLE_OAUTH_CLIENT_IDS`
4. Valor: cole o Web Client ID do Passo 5 (se tiver mais de um, separe por vírgula, sem espaços)
5. Save → Render vai redeployar sozinho

---

## Passo 7 — Testar

1. Build novo APK via CI (`git push` já é suficiente)
2. Instale no seu S25
3. Abra o app → tela de login → **"Continuar com Google"**
4. Escolha sua conta Google → deve entrar direto no Dashboard

### Se falhar

Erros mais comuns e o que significam:

| Erro | Causa | Solução |
|---|---|---|
| "DEVELOPER_ERROR" | SHA-1 errado no Firebase | Volte no Passo 3 e verifique |
| "Login social ainda não configurado no servidor" | Var `GOOGLE_OAUTH_CLIENT_IDS` faltando no Render | Passo 6 |
| "Token do Google inválido" | Client ID errado ou expirou | Confira Passo 5 e Passo 6 |
| Tela do Google não abre | `google-services.json` não está em `android/app/` | Passo 2 |

---

## Depois de subir a release (Play Store)

Quando o CI passar a assinar com a **release keystore** própria (semana 2 do plano):

1. Rode `keytool` de novo apontando pra release keystore
2. Adicione a nova SHA-1 no Firebase (Passo 2 — pode ter várias)
3. Quando publicar via Play Console, o Google gera **outra** SHA-1 (do "App Signing by Google Play") — adicione essa também. Ela fica em Play Console → Setup → App integrity → App signing key certificate

---

## O que ficará automático depois disso

Quando os 7 passos estiverem prontos:
- Botão "Continuar com Google" funciona sem novas configurações
- Contas novas via Google entram já com nome e email preenchidos
- Contas Google não precisam de senha (marker aleatório no backend impede login por senha nessas contas)
- Consentimentos LGPD são registrados automaticamente ao entrar

O **Apple Sign-In** virá em lote separado (só relevante quando publicarmos na App Store).
