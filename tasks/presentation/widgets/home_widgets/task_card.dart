// lib/features/tasks/presentation/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/extensions/datetime_extensions.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/task_state_notifier.dart';
import '../../pages/edit_task_page.dart';

class TaskCard extends ConsumerWidget {
  final TaskEntity task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final error = await ref
            .read(taskStateNotifierProvider.notifier)
            .deleteTask(task.id);
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: AppColors.completed,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTaskPage(task: task),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _getPriorityColor(task.priority).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () async {
                    if (task.status == TaskStatus.overdue &&
                        task.permanentlyOverdue) {
                      _showCannotCompleteDialog(context);
                      return;
                    }
                    final error = await ref
                        .read(taskStateNotifierProvider.notifier)
                        .toggleTaskStatus(task.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? AppColors.completed
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? AppColors.completed
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Task Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color:
                              task.isCompleted ? Colors.grey : Colors.black87,
                        ),
                      ),

                      // Description
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Bottom Row: Date and Priority
                      Row(
                        children: [
                          // Date
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getDateColor(task).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: _getDateColor(task),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getDateColor(task),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Priority
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _getPriorityIcon(task.priority,
                                    size: 12,
                                    color: _getPriorityColor(task.priority)),
                                const SizedBox(width: 4),
                                Text(
                                  _getPriorityText(task.priority),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPriorityColor(task.priority),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Overdue/Locked badge
                          if (task.isOverdue) ...[
                            const SizedBox(width: 8),
                            if (task.permanentlyOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'LOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              StreamBuilder<DateTime>(
                                stream: Stream.periodic(
                                  const Duration(seconds: 1),
                                  (_) => DateTime.now(),
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final now = snapshot.data!;
                                  final graceEnd = task.dueDate.add(
                                    const Duration(hours: 24),
                                  );
                                  final remaining = graceEnd.difference(now);
                                  final timeStr =
                                      _formatRemainingTime(remaining);
                                  final isExpired = remaining.isNegative;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpired
                                          ? AppColors.error.withOpacity(0.1)
                                          : AppColors.overdue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isExpired ? 'LOCKED' : timeStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isExpired
                                            ? AppColors.error
                                            : AppColors.overdue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) {
      return '00:00:00';
    }
    final hours = (remaining.inHours).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showCannotCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Locked Task'),
        content: const Text(
            'This task is permanently overdue and cannot be marked as complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.highPriority;
      case TaskPriority.medium:
        return AppColors.mediumPriority;
      case TaskPriority.low:
        return AppColors.lowPriority;
    }
  }

  Widget _getPriorityIcon(TaskPriority priority, {double? size, Color? color}) {
    late IconData iconData;
    switch (priority) {
      case TaskPriority.high:
        iconData = Icons.keyboard_double_arrow_up_rounded;
        break;
      case TaskPriority.medium:
        iconData = Icons.linear_scale_sharp;
        break;
      case TaskPriority.low:
        iconData = Icons.keyboard_double_arrow_down_rounded;
        break;
    }
    return Icon(
      iconData,
      size: size ?? 24.0, // Default size if not provided
      color: color ?? Colors.grey, // Default color if not provided
    );
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color _getDateColor(TaskEntity task) {
    if (task.isCompleted) return AppColors.completed;
    if (task.isOverdue) return AppColors.overdue;
    if (task.dueDate.isToday) return AppColors.mediumPriority;
    return Colors.grey.shade600;
  }

  String _formatDate(DateTime date) {
    if (date.isToday) return 'Today';
    if (date.isTomorrow) return 'Tomorrow';
    return date.formattedDate;
  }
}
