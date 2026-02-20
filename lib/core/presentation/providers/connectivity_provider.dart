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
    // Primera verificación
    bool isConnected = await _performConnectivityCheck();

    // Si falla, hacemos doble check para evitar falsos positivos (flickering)
    if (!isConnected) {
      await Future.delayed(const Duration(seconds: 2));
      isConnected = await _performConnectivityCheck();
    }

    // Actualizar estado
    if (isConnected) {
      if (!_isOnline) {
        _isOnline = true;
        debugPrint('🌐 Estado de conexión: ONLINE (restablecido)');
        notifyListeners();
      }
    } else {
      // Solo marcamos offline si fallaron ambos intentos
      if (_isOnline) {
        _isOnline = false;
        debugPrint('🌐 Estado de conexión: OFFLINE (confirmado)');
        notifyListeners();
      }
    }
  }

  /// Ejecuta un ping a Firestore para verificar conexión real
  Future<bool> _performConnectivityCheck() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('_connectivity_check')
          .doc('ping');

      await docRef.get(const GetOptions(source: Source.server)).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Connection check timeout');
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}
