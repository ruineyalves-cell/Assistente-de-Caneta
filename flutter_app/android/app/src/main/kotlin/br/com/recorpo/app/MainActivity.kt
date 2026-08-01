package br.com.recorpo.app

import io.flutter.embedding.android.FlutterFragmentActivity

// IMPORTANTE: precisa ser FlutterFragmentActivity (não FlutterActivity).
// O plugin local_auth usa BiometricPrompt, que exige uma FragmentActivity
// como host. Com FlutterActivity, authenticate() lança
// PlatformException("no_fragment_activity") ANTES de mostrar o diálogo de
// digital — a tela de login "piscava" e não entrava. Trocar a base resolve
// o login biométrico de forma definitiva.
class MainActivity : FlutterFragmentActivity()
