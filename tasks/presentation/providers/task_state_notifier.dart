import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/toggle_task_status.dart';
import '../../domain/usecases/update_task.dart';
import 'task_providers.dart';

class TaskState {
  final List<TaskEntity> tasks;
  final bool isLoading;
  final String? error;

  TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TaskStateNotifier extends StateNotifier<TaskState> {
  final GetTasks getTasksUseCase;
  final CreateTask createTaskUseCase;
  final UpdateTask updateTaskUseCase;
  final DeleteTask deleteTaskUseCase;
  final ToggleTaskStatus toggleTaskStatusUseCase;

  TaskStateNotifier({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.toggleTaskStatusUseCase,
  }) : super(TaskState());

  Future<String?> loadTasks(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await getTasksUseCase(userId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return failure.message;
      },
      (tasks) {
        state = state.copyWith(
          tasks: tasks,
          isLoading: false,
          error: null,
        );
        return null;
      },
    );
  }

  Future<String?> createTask(TaskEntity task) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await createTaskUseCase(task);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return failure.message;
      },
      (createdTask) {
        state = state.copyWith(
          tasks: [createdTask, ...state.tasks],
          isLoading: false,
          error: null,
        );
        return null;
      },
    );
  }

  Future<String?> updateTask(TaskEntity task) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await updateTaskUseCase(task);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return failure.message;
      },
      (updatedTask) {
        final updatedTasks = state.tasks.map((t) {
          return t.id == updatedTask.id ? updatedTask : t;
        }).toList();

        state = state.copyWith(
          tasks: updatedTasks,
          isLoading: false,
          error: null,
        );
        return null;
      },
    );
  }

  Future<String?> deleteTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await deleteTaskUseCase(taskId);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return failure.message;
      },
      (_) {
        final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
        state = state.copyWith(
          tasks: updatedTasks,
          isLoading: false,
          error: null,
        );
        return null;
      },
    );
  }

  Future<String?> toggleTaskStatus(String taskId) async {
    final result = await toggleTaskStatusUseCase(taskId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return failure.message;
      },
      (updatedTask) {
        final updatedTasks = state.tasks.map((t) {
          return t.id == updatedTask.id ? updatedTask : t;
        }).toList();

        state = state.copyWith(tasks: updatedTasks, error: null);
        return null;
      },
    );
  }
}

// Provider
final taskStateNotifierProvider =
    StateNotifierProvider<TaskStateNotifier, TaskState>((ref) {
  return TaskStateNotifier(
    getTasksUseCase: ref.watch(getTasksUseCaseProvider),
    createTaskUseCase: ref.watch(createTaskUseCaseProvider),
    updateTaskUseCase: ref.watch(updateTaskUseCaseProvider),
    deleteTaskUseCase: ref.watch(deleteTaskUseCaseProvider),
    toggleTaskStatusUseCase: ref.watch(toggleTaskStatusUseCaseProvider),
  );
});
