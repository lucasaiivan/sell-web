import 'package:sellweb/core/config/oauth_config.dart';

/// Configuración central de la aplicación
/// 
/// Esta clase centraliza todas las configuraciones de la aplicación
/// para mantener un único punto de verdad y facilitar el mantenimiento.
class AppConfig {
  // Prevenir instanciación
  AppConfig._();

  /// Configuración de Google Sign-In
  static Map<String, dynamic> get googleSignInConfig => {
    'scopes': OAuthConfig.googleSignInScopes,
    'clientId': OAuthConfig.googleSignInClientId,
  };

  /// Nombre de la aplicación
  static const String appName = 'Sell Web';

  /// Configuración de debug
  static const bool debugShowCheckedModeBanner = false;

  /// Configuración de título de la aplicación
  static const String appTitle = 'Sell Web';
}
