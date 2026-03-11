import 'package:injectable/injectable.dart';
import '../repositories/i_cloud_print_repository.dart';

/// Caso de uso para limpiar completamente la cola de impresión de un negocio.
///
/// Elimina TODOS los documentos de la colección PRINTING_RECEIPTS de forma
/// atómica mediante un WriteBatch, garantizando consistencia en Firestore.
@lazySingleton
class ClearPrintQueueUseCase {
  final ICloudPrintRepository _repository;

  ClearPrintQueueUseCase(this._repository);

  Future<void> call(String businessId) async {
    await _repository.clearPrintQueue(businessId: businessId);
  }
}
