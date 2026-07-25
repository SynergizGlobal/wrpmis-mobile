import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:wr_pmis_mobile/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<AuthSession>> login({
    required String userId,
    required String password,
  }) async {
    try {
      final session = await _remote.login(userId: userId, password: password);
      return Right(session);
    } on DioException catch (error) {
      return Left(Failure(error.message ?? 'Login failed'));
    } catch (error) {
      return Left(Failure(error.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logoutSession();
      return const Right(null);
    } on DioException catch (error) {
      return Left(Failure(error.message ?? 'Logout failed'));
    } catch (error) {
      return Left(Failure(error.toString()));
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});
