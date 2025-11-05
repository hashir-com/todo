// lib/features/tasks/domain/entities/task_entity.dart
import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, completed, overdue }

class TaskEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final bool permanentlyOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.permanentlyOverdue,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    bool? permanentlyOverdue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      permanentlyOverdue: permanentlyOverdue ?? this.permanentlyOverdue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isOverdue => status == TaskStatus.overdue;
  bool get isLocked => status == TaskStatus.overdue && permanentlyOverdue;

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        dueDate,
        priority,
        status,
        permanentlyOverdue,
        createdAt,
        updatedAt,
      ];
}