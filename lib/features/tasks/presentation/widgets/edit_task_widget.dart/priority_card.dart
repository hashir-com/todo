// lib/features/tasks/presentation/widgets/priority_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/core/theme/app_colors.dart';
import 'package:todo_app_pro/features/tasks/presentation/providers/edit_task_notifier.dart';
import '../../../domain/entities/task_entity.dart';
import 'priority_button.dart';

class PriorityCard extends ConsumerWidget {
  final TaskEntity task;
  final bool isLoading;

  const PriorityCard({
    super.key,
    required this.task,
    required this.isLoading,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editTaskNotifierProvider(task));
    final notifier = ref.read(editTaskNotifierProvider(task).notifier);
    final currentPriorityColor = _getPriorityColor(state.selectedPriority);

    return Card(
      elevation: 10,
      shadowColor: currentPriorityColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: currentPriorityColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PriorityButton(
                    label: 'Low',
                    icon: Icons.keyboard_double_arrow_down_outlined,
                    color: AppColors.lowPriority,
                    isSelected: state.selectedPriority == TaskPriority.low,
                    onTap: () => notifier.updatePriority(TaskPriority.low),
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PriorityButton(
                    label: 'Medium',
                    icon: Icons.density_medium_outlined,
                    color: AppColors.mediumPriority,
                    isSelected: state.selectedPriority == TaskPriority.medium,
                    onTap: () => notifier.updatePriority(TaskPriority.medium),
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PriorityButton(
                    label: 'High',
                    icon: Icons.keyboard_double_arrow_up_outlined,
                    color: AppColors.highPriority,
                    isSelected: state.selectedPriority == TaskPriority.high,
                    onTap: () => notifier.updatePriority(TaskPriority.high),
                    enabled: !isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
