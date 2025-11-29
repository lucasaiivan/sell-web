import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider que gestiona el estado de conectividad de la aplicación
///
/// Monitorea el estado de conexión de Firestore para saber si la app
/// está en modo online u offline. Esto permite mostrar indicadores visuales
/// y tomar decisiones basadas en la disponibilidad de red.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  Timer? _connectivityTimer;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectivityProvider() {
    _startMonitoring();
  }

  /// Inicia el monitoreo del estado de conexión
  ///
  /// Usa una estrategia de polling que intenta escribir en Firestore
  /// para determinar si hay conexión real con el servidor.
  void _startMonitoring() {
    // Verificar inmediatamente al inicio
    _checkConnectivity();

    // Verificar cada 10 segundos
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Verifica el estado de conectividad intentando acceder a Firestore
  Future<void> _checkConnectivity() async {
    try {
      // Intentar leer un documento pequeño con timeout corto
      // Usamos getOptions para forzar lectura desde servidor
      final docRef = FirebaseFirestore.instance
          .collection('_connectivity_check')
          .doc('ping');

      // Intentar leer desde el servidor (no desde caché)
      await docRef
          .get(const GetOptions(source: Source.server))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // Si el timeout expira, asumir offline
              throw TimeoutException('Connection check timeout');
            },
          );

      // Si llegamos aquí, hay conexión
      final wasOnline = _isOnline;
      _isOnline = true;

      if (!wasOnline) {
        debugPrint('🌐 Estado de conexión: ONLINE (reconectado)');
        notifyListeners();
      }
    } catch (e) {
      // Error o timeout = sin conexión
      final wasOnline = _isOnline;
      _isOnline = false;

      if (wasOnline) {
        debugPrint('🌐 Estado de conexión: OFFLINE');
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}
