// toggle_task_status.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class ToggleTaskStatus implements UseCase<TaskEntity, String> {
  final TaskRepository repository;

  ToggleTaskStatus(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(String taskId) {
    return repository.toggleTaskStatus(taskId);
  }
}