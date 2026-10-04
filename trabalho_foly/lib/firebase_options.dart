import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configurações do Firebase geradas manualmente.
/// Recomendo no futuro rodar `flutterfire configure` para gerar
/// esse arquivo automaticamente para Android/iOS também.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Configuração do Android ainda não adicionada. '
          'Rode `flutterfire configure` para gerar.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Configuração do iOS ainda não adicionada. '
          'Rode `flutterfire configure` para gerar.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCLqselTaMVeCqXsw6M-YFXJKBkspiK49E",
    authDomain: "pdm-jm.firebaseapp.com",
    projectId: "pdm-jm",
    storageBucket: "pdm-jm.firebasestorage.app",
    messagingSenderId: "104620007896",
    appId: "1:104620007896:web:0246688201df75d7fa52ad",
  );
}