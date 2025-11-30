import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../../../auth/data/models/admin_profile_model.dart';
import '../../domain/repositories/multi_user_repository.dart';
import '../datasources/multi_user_remote_datasource.dart';

@LazySingleton(as: MultiUserRepository)
class MultiUserRepositoryImpl implements MultiUserRepository {
  final MultiUserRemoteDataSource remoteDataSource;

  MultiUserRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<AdminProfile>>> getUsers(String accountId) {
    return remoteDataSource.getUsers(accountId).transform(
          StreamTransformer<List<AdminProfileModel>,
              Either<Failure, List<AdminProfile>>>.fromHandlers(
            handleData: (data, sink) {
              sink.add(Right(data));
            },
            handleError: (error, stackTrace, sink) {
              sink.add(Left(ServerFailure(error.toString())));
            },
          ),
        );
  }

  @override
  Future<Either<Failure, void>> createUser(
      AdminProfile user, String accountId) async {
    try {
      await remoteDataSource.createUser(user, accountId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(
      AdminProfile user, String accountId) async {
    try {
      await remoteDataSource.updateUser(user, accountId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(
      AdminProfile user, String accountId) async {
    try {
      await remoteDataSource.deleteUser(user, accountId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
