import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // O plugin Google Services precisa ficar aqui pra o google-services.json
    // ser processado no build. Sem ele o Firebase Auth (Lote 20) não conecta.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties (criado pelo CI a partir dos secrets — nunca commitado).
// Ausente localmente: build usa a keystore de debug automaticamente.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKeystore = keystorePropertiesFile.exists() &&
    keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "br.com.recorpo.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.recorpo.app"
        // Health Connect (Lote 11) exige API >= 26; libs de câmera/OCR
        // usadas nos Lotes 9-10 também rodam melhor a partir daí.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 é ativado (necessário para as regras de `-dontwarn` do
            // proguard-rules.pro ancorarem — sem elas o mlkit trava o
            // build). shrinkResources fica desligado: se você ativar,
            // ele remove drawables/XML que o Flutter engine usa no
            // startup e o app aparece como "falhas contínuas" no S25.
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
