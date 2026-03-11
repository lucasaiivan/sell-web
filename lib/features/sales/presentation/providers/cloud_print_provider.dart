import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/domain/usecases/clear_print_queue_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/enqueue_print_job_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/get_print_queue_stream_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/remove_print_job_usecase.dart';

/// Provider de estado para la impresión en la nube (Cloud Print).
///
/// Refleja la acción de subir el ticket a Firestore y maneja su estado
/// de carga e error para mostrar feedback claro en la UI.
@injectable
class CloudPrintProvider extends ChangeNotifier {
  final EnqueuePrintJobUseCase _enqueuePrintJobUseCase;
  final GetPrintQueueStreamUseCase _getPrintQueueStreamUseCase;
  final RemovePrintJobUseCase _removePrintJobUseCase;
  final ClearPrintQueueUseCase _clearPrintQueueUseCase;

  bool _isEnqueuing = false;
  String? _lastError;

  CloudPrintProvider(
    this._enqueuePrintJobUseCase,
    this._getPrintQueueStreamUseCase,
    this._removePrintJobUseCase,
    this._clearPrintQueueUseCase,
  );

  bool get isEnqueuing => _isEnqueuing;
  String? get lastError => _lastError;

  /// Encola un ticket en Firebase para el nodo de Windows.
  ///
  /// Recibe un [businessId] para identificar en qué ruta guardar, y un
  /// [job] con los datos a imprimir.
  Future<bool> enqueueTicket({
    required String businessId,
    required TicketModel job,
  }) async {
    _isEnqueuing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _enqueuePrintJobUseCase(
        EnqueuePrintJobParams(businessId: businessId, job: job),
      );

      _isEnqueuing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isEnqueuing = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetError() {
    _lastError = null;
    notifyListeners();
  }

  /// Obtiene un Stream de los tickets pendientes en la cola para un negocio.
  Stream<List<TicketModel>> getTicketQueue(String businessId) {
    return _getPrintQueueStreamUseCase(businessId);
  }

  /// Elimina un ticket de la cola.
  Future<bool> removeTicket(String businessId, String ticketId) async {
    try {
      await _removePrintJobUseCase(
        RemovePrintJobParams(businessId: businessId, jobId: ticketId),
      );
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina TODOS los tickets de la cola de impresión de un negocio.
  Future<bool> clearQueue(String businessId) async {
    try {
      await _clearPrintQueueUseCase(businessId);
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
