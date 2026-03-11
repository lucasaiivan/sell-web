import '../entities/ticket_model.dart';

abstract class ICloudPrintRepository {
  /// Obtiene el flujo de tickets de impresión en la nube.
  Stream<List<TicketModel>> getPrintQueue(String businessId);

  /// Agrega un ticket a la cola de impresión.
  Future<void> enqueuePrintJob({
    required String businessId,
    required TicketModel job,
  });

  /// Elimina un ticket de la cola de impresión.
  Future<void> removePrintJob({
    required String businessId,
    required String jobId,
  });

  /// Elimina TODOS los tickets de la cola de impresión de un negocio.
  Future<void> clearPrintQueue({required String businessId});
}
