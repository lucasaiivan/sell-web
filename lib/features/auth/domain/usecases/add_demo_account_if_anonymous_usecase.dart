import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_profile.dart';
import 'get_demo_account_usecase.dart';

/// Parámetros para AddDemoAccountIfAnonymousUseCase
class AddDemoAccountIfAnonymousParams {
  final List<AccountProfile> accounts;
  final bool isAnonymous;

  const AddDemoAccountIfAnonymousParams({
    required this.accounts,
    required this.isAnonymous,
  });
}

/// Caso de uso: Añadir cuenta demo a lista si usuario es anónimo
///
/// **Responsabilidad:**
/// - Añade la cuenta demo a la lista de cuentas si el usuario es invitado
@lazySingleton
class AddDemoAccountIfAnonymousUseCase
    extends UseCase<List<AccountProfile>, AddDemoAccountIfAnonymousParams> {
  final GetDemoAccountUseCase _getDemoAccountUseCase;

  AddDemoAccountIfAnonymousUseCase(this._getDemoAccountUseCase);

  /// Ejecuta la adición de cuenta demo si aplica
  ///
  /// Retorna [Right(List<AccountProfile>)] con la lista actualizada
  @override
  Future<Either<Failure, List<AccountProfile>>> call(
      AddDemoAccountIfAnonymousParams params) async {
    final result = List<AccountProfile>.from(params.accounts);

    if (params.isAnonymous) {
      final demoResult = await _getDemoAccountUseCase(const NoParams());

      return demoResult.fold(
        (failure) => Left(failure),
        (demoAccount) {
          result.add(demoAccount);
          return Right(result);
        },
      );
    }

    return Right(result);
  }
}
