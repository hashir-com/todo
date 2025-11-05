import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks(String userId);
  
  Future<Either<Failure, TaskEntity>> getTaskById(String taskId);
  
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task);
  
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task);
  
  Future<Either<Failure, void>> deleteTask(String taskId);
  
  Future<Either<Failure, TaskEntity>> toggleTaskStatus(String taskId);
  
  Stream<Either<Failure, List<TaskEntity>>> watchTasks(String userId);
}