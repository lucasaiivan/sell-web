import 'firebase_options.dart';

/// Configuración de OAuth centralizada para la aplicación
///
/// Esta clase maneja todas las configuraciones relacionadas con OAuth
/// de manera centralizada y segura.
class OAuthConfig {
  // Prevenir instanciación
  OAuthConfig._();

  /// Google Sign-In Client ID para Flutter Web
  ///
  /// Obtiene el Client ID desde firebase_options.dart para mantener
  /// una única fuente de verdad y evitar duplicación de configuraciones.
  ///
  /// Este ID debe:
  /// 1. Coincidir con el configurado en web/index.html
  /// 2. Estar registrado en Google Cloud Console
  /// 3. Tener los dominios autorizados configurados
  static String get googleSignInClientId =>
      DefaultFirebaseOptions.googleSignInClientId;

  /// Scopes requeridos para Google Sign-In
  static const List<String> googleSignInScopes = [
    'email',
    'profile',
  ];

  /// Configuración completa para GoogleSignIn
  static Map<String, dynamic> get googleSignInConfig => {
        'clientId': googleSignInClientId,
        'scopes': googleSignInScopes,
      };
}
