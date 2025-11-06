// lib/features/tasks/presentation/widgets/status_toggle_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/core/theme/app_colors.dart';
import 'package:todo_app_pro/features/tasks/presentation/providers/edit_task_notifier.dart';
import 'package:todo_app_pro/features/tasks/presentation/providers/task_state_notifier.dart';
import '../../../domain/entities/task_entity.dart';

class StatusToggleCard extends ConsumerWidget {
  final TaskEntity task;
  final bool isLocked;
  final Color statusColor;
  final IconData statusIcon;
  final String statusText;
  final bool isDuePast;
  final bool switchValue;
  final bool isLoading;

  const StatusToggleCard({
    super.key,
    required this.task,
    required this.isLocked,
    required this.statusColor,
    required this.statusIcon,
    required this.statusText,
    required this.isDuePast,
    required this.switchValue,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editTaskNotifierProvider(task).notifier);
    final taskNotifier = ref.read(taskStateNotifierProvider.notifier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 8,
        shadowColor: statusColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: isLocked
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Permanently Overdue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cannot complete',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Hero(
                      tag: 'status-icon-${task.id}',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            isDuePast ? 'Due date passed' : 'On track',
                            style: TextStyle(
                              fontSize: 14,
                              color: statusColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Switch(
                        key: ValueKey(switchValue),
                        value: switchValue,
                        onChanged: isLoading
                            ? null
                            : (value) async {
                                // Optimistic update
                                notifier.updateIsCompleted(value);
                                final error = await taskNotifier
                                    .toggleTaskStatus(task.id);
                                if (error != null) {
                                  // Revert on error
                                  notifier.updateIsCompleted(!value);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        activeColor: AppColors.completed,
                        activeTrackColor: AppColors.completed.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
