import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/tasks/domain/entities/task_entity.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/toggle_task_status.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/watch_tasks.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Data sources
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSourceImpl();
});

// Repository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    remoteDataSource: ref.watch(taskRemoteDataSourceProvider),
    localDataSource: ref.watch(taskLocalDataSourceProvider),
  );
});

// Use cases
final getTasksUseCaseProvider = Provider<GetTasks>((ref) {
  return GetTasks(ref.watch(taskRepositoryProvider));
});

final createTaskUseCaseProvider = Provider<CreateTask>((ref) {
  return CreateTask(ref.watch(taskRepositoryProvider));
});

final updateTaskUseCaseProvider = Provider<UpdateTask>((ref) {
  return UpdateTask(ref.watch(taskRepositoryProvider));
});

final deleteTaskUseCaseProvider = Provider<DeleteTask>((ref) {
  return DeleteTask(ref.watch(taskRepositoryProvider));
});

final toggleTaskStatusUseCaseProvider = Provider<ToggleTaskStatus>((ref) {
  return ToggleTaskStatus(ref.watch(taskRepositoryProvider));
});

final watchTasksUseCaseProvider = Provider<WatchTasks>((ref) {
  return WatchTasks(ref.watch(taskRepositoryProvider));
});

// Tasks stream provider
final tasksStreamProvider = StreamProvider.autoDispose((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<TaskEntity>[]);
      }
      final watchTasks = ref.watch(watchTasksUseCaseProvider);
      return watchTasks(user.id).map((either) {
        return either.fold(
          (failure) => <TaskEntity>[],
          (tasks) => tasks,
        );
      });
    },
    loading: () => Stream.value(<TaskEntity>[]),
    error: (_, __) => Stream.value(<TaskEntity>[]),
  );
});