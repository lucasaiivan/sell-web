// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Implementación Web usando dart:html
void enterFullScreen() {
  try {
    html.document.documentElement?.requestFullscreen();
  } catch (e) {
    // Ignorar errores de permisos o si el navegador no lo soporta
    print('Error al intentar pantalla completa: $e');
  }
}

void exitFullScreen() {
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (e) {
    print('Error al salir de pantalla completa: $e');
  }
}
