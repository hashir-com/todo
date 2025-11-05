// lib/features/tasks/presentation/providers/edit_task_state.dart
import 'package:equatable/equatable.dart';
import 'package:todo_app_pro/features/tasks/domain/entities/task_entity.dart';

class EditTaskState extends Equatable {
  final bool isLoading;
  final DateTime selectedDate;
  final TaskPriority selectedPriority;
  final bool selectedIsCompleted;

  const EditTaskState({
    this.isLoading = false,
    required this.selectedDate,
    required this.selectedPriority,
    required this.selectedIsCompleted,
  });

  EditTaskState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    TaskPriority? selectedPriority,
    bool? selectedIsCompleted,
  }) {
    return EditTaskState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      selectedIsCompleted: selectedIsCompleted ?? this.selectedIsCompleted,
    );
  }

  @override
  List<Object?> get props => [isLoading, selectedDate, selectedPriority, selectedIsCompleted];
}