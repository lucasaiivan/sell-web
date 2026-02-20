// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Descarga bytes como un archivo en el navegador.
///
/// Crea un AnchorElement temporal, asigna el blob URL y simula un click.
void downloadFile(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  
  html.Url.revokeObjectUrl(url);
}
