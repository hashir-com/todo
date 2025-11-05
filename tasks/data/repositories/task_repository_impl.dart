import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_app_pro/features/tasks/data/models/task_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // Helper method to get current user ID
  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }
    return user.uid;
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks(String userId) async {
    try {
      final tasks = await remoteDataSource.getTasks(userId);
      await localDataSource.cacheTasks(tasks);
      return Right(tasks.map((task) => task.toEntity()).toList());
    } on ServerException catch (e) {
      // Try to get from cache
      try {
        final cachedTasks = await localDataSource.getCachedTasks();
        return Right(cachedTasks.map((task) => task.toEntity()).toList());
      } catch (_) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to fetch tasks'));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskById(String taskId) async {
    try {
      final userId = _getCurrentUserId();
      final task = await remoteDataSource.getTaskById(taskId, userId);
      await localDataSource.cacheTask(task);
      return Right(task.toEntity());
    } on ServerException catch (e) {
      // Try to get from cache
      try {
        final cachedTask = await localDataSource.getCachedTask(taskId);
        if (cachedTask != null) {
          return Right(cachedTask.toEntity());
        }
        return Left(ServerFailure('Task not found'));
      } catch (_) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to fetch task'));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task) async {
    try {
      final taskModel = await remoteDataSource.createTask(
        TaskModel.fromEntity(task),
      );
      await localDataSource.cacheTask(taskModel);
      return Right(taskModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create task'));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task) async {
    try {
      final taskModel = await remoteDataSource.updateTask(
        TaskModel.fromEntity(task),
      );
      await localDataSource.cacheTask(taskModel);
      return Right(taskModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update task'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      final userId = _getCurrentUserId();
      await remoteDataSource.deleteTask(taskId, userId);
      await localDataSource.deleteTask(taskId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete task'));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> toggleTaskStatus(String taskId) async {
    try {
      final userId = _getCurrentUserId();
      final task = await remoteDataSource.toggleTaskStatus(taskId, userId);
      await localDataSource.cacheTask(task);
      return Right(task.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to toggle task status'));
    }
  }

  @override
  Stream<Either<Failure, List<TaskEntity>>> watchTasks(String userId) {
    try {
      return remoteDataSource.watchTasks(userId).map((tasks) {
        // Cache tasks in background
        localDataSource.cacheTasks(tasks);
        return Right<Failure, List<TaskEntity>>(
          tasks.map((task) => task.toEntity()).toList(),
        );
      }).handleError((error) {
        return Left<Failure, List<TaskEntity>>(
          ServerFailure('Failed to watch tasks'),
        );
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch tasks')));
    }
  }
}
