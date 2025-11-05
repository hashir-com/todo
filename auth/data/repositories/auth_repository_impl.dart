import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmail(email, password);
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Google sign in failed'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(
        email,
        password,
        displayName,
      );
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Sign up failed'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Sign out failed'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      if (user != null) {
        await localDataSource.cacheUser(user);
        return Right(user.toEntity());
      }
      
      // Try to get from cache
      final cachedUser = await localDataSource.getCachedUser();
      return Right(cachedUser?.toEntity());
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Password reset failed'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('Failed to send verification email'));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges
        .map((user) => user?.toEntity());
  }
}