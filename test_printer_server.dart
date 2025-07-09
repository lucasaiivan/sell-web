#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

void main() async {
  const String baseUrl = 'http://localhost:8080';

  print('=== Test Printer Server ===');
  print('Verificando estado del servidor de impresora...\n');

  final client = HttpClient();

  try {
    // 1. Verificar estado del servidor
    print('🔄 Verificando /status...');
    final statusRequest = await client.getUrl(Uri.parse('$baseUrl/status'));
    final statusResponse = await statusRequest.close();
    final statusBody = await statusResponse.transform(utf8.decoder).join();

    print('✅ Status: ${statusResponse.statusCode}');
    print('📄 Response: $statusBody\n');

    // 2. Probar endpoint de impresión con datos de prueba
    print('🔄 Probando /print-ticket...');
    final ticketData = {
      'businessName': 'Test Store - Flutter Web',
      'products': [
        {
          'quantity': '2',
          'description': 'Producto Test A',
          'price': 15.50,
        },
        {
          'quantity': '1',
          'description': 'Producto Test B',
          'price': 25.00,
        }
      ],
      'total': 56.00,
      'paymentMethod': 'Efectivo',
      'customerName': 'Cliente Test',
      'cashReceived': 60.00,
      'change': 4.00,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final printRequest =
        await client.postUrl(Uri.parse('$baseUrl/print-ticket'));
    printRequest.headers.set('Content-Type', 'application/json');
    printRequest.write(jsonEncode(ticketData));

    final printResponse = await printRequest.close();
    final printBody = await printResponse.transform(utf8.decoder).join();

    print('✅ Print Status: ${printResponse.statusCode}');
    print('📄 Print Response: $printBody\n');

    if (printResponse.statusCode == 200) {
      print('🎉 ¡Ticket enviado exitosamente!');
    } else {
      print('❌ Error al enviar ticket');
    }
  } catch (e) {
    print('❌ Error de conexión: $e');
    print('💡 Asegúrate de que la aplicación SellPOS esté ejecutándose');
  } finally {
    client.close();
  }

  print('\n=== Fin del Test ===');
}
