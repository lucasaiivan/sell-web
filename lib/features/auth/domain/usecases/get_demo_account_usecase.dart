import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_profile.dart';

/// Caso de uso: Obtener cuenta demo para usuarios invitados
///
/// **Responsabilidad:**
/// - Genera un AccountProfile de prueba para modo invitado
@lazySingleton
class GetDemoAccountUseCase extends UseCase<AccountProfile, NoParams> {
  GetDemoAccountUseCase();

  /// Ejecuta la generación de cuenta demo
  ///
  /// Retorna [Right(AccountProfile)] con la cuenta demo
  @override
  Future<Either<Failure, AccountProfile>> call(NoParams params) async {
    try {
      final demoAccount = AccountProfile(
        id: 'demo',
        name: 'Negocio de Prueba',
        country: 'Argentina',
        province: 'Buenos Aires',
        town: 'Demo City',
        image: 'https://cdn-icons-png.flaticon.com/512/869/869636.png',
        currencySign: '\$',
        creation: DateTime.now(),
        trialStart: DateTime.now(),
        trialEnd: DateTime.now().add(const Duration(days: 30)),
      );
      
      return Right(demoAccount);
    } catch (e) {
      return Left(ServerFailure('Error al generar cuenta demo: ${e.toString()}'));
    }
  }
}
