import 'package:injectable/injectable.dart';
import '../entities/ticket_model.dart';
import '../repositories/i_cloud_print_repository.dart';

@lazySingleton
class EnqueuePrintJobUseCase {
  final ICloudPrintRepository _repository;

  EnqueuePrintJobUseCase(this._repository);

  Future<void> call(EnqueuePrintJobParams params) async {
    await _repository.enqueuePrintJob(
      businessId: params.businessId,
      job: params.job,
    );
  }
}

class EnqueuePrintJobParams {
  final String businessId;
  final TicketModel job;

  EnqueuePrintJobParams({
    required this.businessId,
    required this.job,
  });
}
