import 'package:injectable/injectable.dart';
import '../repositories/i_cloud_print_repository.dart';

@lazySingleton
class RemovePrintJobUseCase {
  final ICloudPrintRepository _repository;

  RemovePrintJobUseCase(this._repository);

  Future<void> call(RemovePrintJobParams params) async {
    await _repository.removePrintJob(
      businessId: params.businessId,
      jobId: params.jobId,
    );
  }
}

class RemovePrintJobParams {
  final String businessId;
  final String jobId;

  RemovePrintJobParams({
    required this.businessId,
    required this.jobId,
  });
}
