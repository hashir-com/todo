import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_state_notifier.dart';

class AddTaskState {
  final bool isLoading;
  final DateTime selectedDate;
  final TaskPriority selectedPriority;

  const AddTaskState({
    this.isLoading = false,
    required this.selectedDate,
    required this.selectedPriority,
  });

  AddTaskState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    TaskPriority? selectedPriority,
  }) {
    return AddTaskState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPriority: selectedPriority ?? this.selectedPriority,
    );
  }
}

class AddTaskNotifier extends StateNotifier<AddTaskState> {
  AddTaskNotifier()
      : super(AddTaskState(
          selectedDate: DateTime.now(),
          selectedPriority: TaskPriority.medium,
        ));

  void updateDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updatePriority(TaskPriority priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  Future<String?> createTask({
    required String title,
    required String description,
    required TaskStateNotifier taskNotifier,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true);
    final task = TaskEntity(
      id: '',
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      dueDate: state.selectedDate,
      priority: state.selectedPriority,
      status: TaskStatus.pending,
      permanentlyOverdue: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final error = await taskNotifier.createTask(task);
    state = state.copyWith(isLoading: false);
    return error;
  }
}

final addTaskNotifierProvider =
    StateNotifierProvider.autoDispose<AddTaskNotifier, AddTaskState>(
  (ref) => AddTaskNotifier(),
);