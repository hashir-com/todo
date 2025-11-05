// watch_tasks.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class WatchTasks {
  final TaskRepository repository;

  WatchTasks(this.repository);

  Stream<Either<Failure, List<TaskEntity>>> call(String userId) {
    return repository.watchTasks(userId);
  }
}