import 'package:injectable/injectable.dart';
import '../entities/ticket_model.dart';
import '../repositories/i_cloud_print_repository.dart';

@lazySingleton
class GetPrintQueueStreamUseCase {
  final ICloudPrintRepository _repository;

  GetPrintQueueStreamUseCase(this._repository);

  Stream<List<TicketModel>> call(String businessId) {
    return _repository.getPrintQueue(businessId);
  }
}
