# Deploy do site Recorpo

## Estado atual (automatizado)

- ✅ Projeto Vercel criado: **ruiney/recorpo**
- ✅ Env vars configuradas (`NEXT_PUBLIC_API_BASE`, `NEXT_PUBLIC_DISABLE_3D`)
- ✅ Deploy em produção rodando: <https://recorpo-hhgvv3kyh-ruiney.vercel.app>
- ✅ Domínios `recorpo.com.br` e `www.recorpo.com.br` já vinculados ao projeto
- ⏳ **DNS no Registro.br — única etapa manual restante** (API pública inexistente)

Cada push em `main` que altere `web/**` faz redeploy automático via GitHub → Vercel.

---

## Único passo manual: apontar DNS no Registro.br

**Escolha UMA opção. A opção A é a mais simples.**

### Opção A — Nameservers da Vercel (recomendado)

Delega DNS inteiro para a Vercel. SSL Let's Encrypt sai automático.

1. Entrar em <https://registro.br/> → Meus Domínios → `recorpo.com.br`
2. Menu **DNS → Alterar Servidores DNS**
3. Substituir os servidores atuais por:
   ```
   ns1.vercel-dns.com
   ns2.vercel-dns.com
   ```
4. Salvar. Propagação: 1h a 24h. Nada mais precisa ser feito.

### Opção B — Manter DNS no Registro.br

Só se você já usa email `@recorpo.com.br` ou outros registros nele.

1. Registro.br → DNS → **Editar Zona**
2. Adicionar dois registros:

   | Tipo  | Nome (Dono) | Dados                     |
   |-------|-------------|---------------------------|
   | A     | `@`         | `76.76.21.21`             |
   | CNAME | `www`       | `cname.vercel-dns.com.`   |

3. Salvar. Propagação: 30 min a 4h.

---

## Verificação

Depois da propagação (pode checar em <https://dnschecker.org/#A/recorpo.com.br>):

- <https://recorpo.com.br> — landing
- <https://recorpo.com.br/privacidade> — LGPD
- <https://recorpo.com.br/portal/login> — portal médico
- <https://recorpo.com.br/sitemap.xml> — indexação Google
- <https://recorpo.com.br/robots.txt>

Cadeado verde em todos = SSL emitido.

---

## Depois do domínio no ar

- **Play Console → Política de Privacidade** → `https://recorpo.com.br/privacidade` (obrigatório para publicar).
- **Play Console → Website** → `https://recorpo.com.br`.
- **Google Search Console** → adicionar `recorpo.com.br` e submeter o sitemap.

---

## Deploy automático via GitHub Actions (opcional)

Existe o workflow `.github/workflows/deploy-web.yml` gate por `vars.ENABLE_VERCEL_DEPLOY == 'true'` (desligado por padrão porque a integração Git da Vercel já cobre 100% do fluxo). Só ligue se quiser controle fino no CI.
