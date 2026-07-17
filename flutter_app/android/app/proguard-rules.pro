# Regras ProGuard/R8 para o build release da Recorpo.

# ------- Flutter engine e plugins ---------
# O Flutter engine e a maior parte dos plugins usam reflection para
# fazer a ponte com o Dart; sem essas regras o app crasha no boot
# ("falhas contínuas" antes mesmo de aparecer a tela de login).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.example.assistente_caneta.** { *; }

# ------- google_mlkit_text_recognition (Lote 10) ----------
# O package referencia por reflection as classes dos scripts opcionais
# (chinês, japonês, coreano, devanagari). Como só usamos Latin, essas
# classes não estão empacotadas — R8 ignora em vez de falhar.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }

# ------- Health Connect (Lote 11) ---------
# O package `health` v13 usa reflection para instanciar records e
# solicitar permissões.
-keep class androidx.health.connect.client.** { *; }
-keep class androidx.health.platform.client.** { *; }
-keep class cachet.plugins.health.** { *; }

# ------- Camera / image_picker (Lotes 9-10) ---------
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# ------- Kotlin stdlib / coroutines (usadas por plugins nativos) ---
-keep class kotlin.Metadata { *; }
-dontwarn kotlinx.**
-keep class kotlinx.coroutines.** { *; }

# ------- Erros de otimização que não afetam runtime ----
-dontwarn org.jetbrains.annotations.**
-dontwarn javax.annotation.**
