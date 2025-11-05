// lib/features/tasks/presentation/providers/edit_task_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/tasks/presentation/state/edit_task_state.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_state_notifier.dart';

class EditTaskNotifier extends StateNotifier<EditTaskState> {
  EditTaskNotifier({
    required DateTime initialDate,
    required TaskPriority initialPriority,
    required bool initialIsCompleted,
  }) : super(EditTaskState(
          selectedDate: initialDate,
          selectedPriority: initialPriority,
          selectedIsCompleted: initialIsCompleted,
        ));

  void updateDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updatePriority(TaskPriority priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  void updateIsCompleted(bool isCompleted) {
    state = state.copyWith(selectedIsCompleted: isCompleted);
  }

  Future<String?> updateTask({
    required TaskEntity originalTask,
    required String title,
    required String description,
    required TaskStateNotifier taskNotifier,
  }) async {
    final titleError = Validators.required(title, 'Title');
    if (titleError != null) return titleError;
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    final isLocked = originalTask.status == TaskStatus.overdue &&
        originalTask.permanentlyOverdue;

    TaskStatus newStatus;
    bool newPermOverdue;
    if (isLocked) {
      newStatus = TaskStatus.overdue;
      newPermOverdue = true;
    } else if (state.selectedIsCompleted) {
      newStatus = TaskStatus.completed;
      newPermOverdue = false;
    } else {
      newStatus = state.selectedDate.isBefore(now)
          ? TaskStatus.overdue
          : TaskStatus.pending;
      newPermOverdue = false;
    }

    final updatedTask = originalTask.copyWith(
      title: title.trim(),
      description: description.trim(),
      dueDate: state.selectedDate,
      priority: state.selectedPriority,
      status: newStatus,
      permanentlyOverdue: newPermOverdue,
      updatedAt: DateTime.now(),
    );

    final error = await taskNotifier.updateTask(updatedTask);
    state = state.copyWith(isLoading: false);

    return error;
  }

  Future<String?> deleteTask({
    required String taskId,
    required TaskStateNotifier taskNotifier,
  }) async {
    state = state.copyWith(isLoading: true);
    final error = await taskNotifier.deleteTask(taskId);
    state = state.copyWith(isLoading: false);

    return error;
  }
}

final editTaskNotifierProvider = StateNotifierProvider.autoDispose
    .family<EditTaskNotifier, EditTaskState, TaskEntity>(
  (ref, task) {
    final initialIsCompleted = task.status == TaskStatus.completed;
    return EditTaskNotifier(
      initialDate: task.dueDate,
      initialPriority: task.priority,
      initialIsCompleted: initialIsCompleted,
    );
  },
);
