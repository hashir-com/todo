import 'package:flutter/material.dart';
import 'package:todo_app_pro/core/theme/app_colors.dart';
import 'package:todo_app_pro/features/tasks/domain/entities/task_entity.dart';
import 'priority_button_widget.dart';

class PrioritySelector extends StatelessWidget {
  final TaskPriority selectedPriority;
  final Function(TaskPriority) onPriorityChanged;
  final bool enabled;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PriorityButton(
            label: 'Low',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.lowPriority,
            isSelected: selectedPriority == TaskPriority.low,
            onTap: () => onPriorityChanged(TaskPriority.low),
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PriorityButton(
            label: 'Medium',
            icon: Icons.remove_rounded,
            color: AppColors.mediumPriority,
            isSelected: selectedPriority == TaskPriority.medium,
            onTap: () => onPriorityChanged(TaskPriority.medium),
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PriorityButton(
            label: 'High',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.highPriority,
            isSelected: selectedPriority == TaskPriority.high,
            onTap: () => onPriorityChanged(TaskPriority.high),
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}