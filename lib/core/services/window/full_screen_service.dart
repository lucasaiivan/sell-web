import 'package:injectable/injectable.dart';
import 'full_screen_helper.dart' as helper;

/// Servicio para gestionar el modo pantalla completa
/// Abstrae la implementación específica de plataforma (Web vs Nativo)
@lazySingleton
class FullScreenService {
  
  /// Activa el modo pantalla completa
  void enterFullScreen() {
    helper.enterFullScreen();
  }

  /// Sale del modo pantalla completa
  void exitFullScreen() {
    helper.exitFullScreen();
  }
}
