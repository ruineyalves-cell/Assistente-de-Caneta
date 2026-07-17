# Regras ProGuard/R8 para o build release da Recorpo.
#
# google_mlkit_text_recognition (Lote 10) referencia por reflection as
# classes dos scripts opcionais (chinês, japonês, coreano, devanagari).
# Como só usamos o script Latin, essas classes não estão empacotadas —
# instruímos o R8 a ignorá-las em vez de falhar.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Preserva as classes do próprio TextRecognizer (Latin) que o Flutter
# plugin instancia via reflection.
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Health Connect (Lote 11): o package `health` v13 usa reflection para
# instanciar records/data classes do Health Connect. Manter todas as
# classes de records evita NoSuchMethodError em release.
-keep class androidx.health.connect.client.** { *; }
-keep class androidx.health.platform.client.** { *; }
