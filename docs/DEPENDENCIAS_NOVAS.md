# Dependências novas a ADICIONAR ao pubspec.yaml existente

> IMPORTANTE: Este arquivo NÃO substitui o seu pubspec.yaml.
> Ele lista só o que precisa ser acrescentado. Deixe o Claude Code
> inserir estas linhas dentro do bloco `dependencies:` que já existe,
> sem apagar nada do que já está lá.

## Como aplicar (cole isto no Claude Code)

```
Adicione as dependências abaixo ao meu pubspec.yaml SEM remover nenhuma
das que já existem. Depois rode `flutter pub get`. Se alguma já estiver
presente, apenas ajuste a versão se a minha for mais antiga; não duplique.

  flutter_riverpod: ^2.5.1          # estado (substitui setState solto)
  shared_preferences: ^2.2.3        # persistir perfil e peso entre sessões
  fl_chart: ^0.68.0                 # gráfico real (corrige o overflow de 4px)
  intl: ^0.19.0                     # datas ("Data da Última Dose")
  image_picker: ^1.1.2              # tirar foto da refeição
  camera: ^0.11.0+2                 # scanner de câmera ao vivo
  google_mlkit_text_recognition: ^0.13.0  # OCR da prescrição nutricional
  health: ^11.0.0                   # Health Connect (FC + gasto ativo do S25)
  pdf: ^3.11.1                      # gerar "PDF para o médico"
  printing: ^5.13.2                 # abrir/compartilhar o PDF
```

## Observações importantes

- `camera`, `image_picker` e `health` exigem permissões no
  `AndroidManifest.xml` (câmera, e Health Connect). Peça ao Claude Code
  para adicioná-las quando for implementar cada recurso — não precisa
  fazer tudo de uma vez.
- `google_mlkit_text_recognition` aumenta o tamanho do APK; é esperado.
- Nada aqui roda no Flutter Web — o teste real é sempre no seu S25 Ultra.
