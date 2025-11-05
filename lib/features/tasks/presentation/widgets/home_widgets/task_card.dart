import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      background: _buildDeleteBackground(),
      confirmDismiss: (_) => _confirmDeleteDialog(context),
      onDismissed: (_) async {
        final error = await ref
            .read(taskStateNotifierProvider.notifier)
            .deleteTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Task deleted successfully'),
              backgroundColor:
                  error == null ? AppColors.completed : AppColors.error,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditTaskPage(task: task)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getPriorityColor(task.priority).withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckbox(context, ref),
              const SizedBox(width: 12),
              Expanded(child: _buildTaskContent(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI Helper Widgets ----------

  Widget _buildDeleteBackground() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      );

  Widget _buildCheckbox(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (task.status == TaskStatus.overdue && task.permanentlyOverdue) {
          _showCannotCompleteDialog(context);
          return;
        }
        final error = await ref
            .read(taskStateNotifierProvider.notifier)
            .toggleTaskStatus(task.id);
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                task.isCompleted ? AppColors.completed : Colors.grey.shade400,
            width: 2,
          ),
          color: task.isCompleted ? AppColors.completed : Colors.transparent,
        ),
        child: task.isCompleted
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
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
              fontSize: 13.5,
              color: Colors.grey[600],
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Bottom Row
        Row(
          children: [
            _buildInfoBadge(
              icon: Icons.calendar_today_rounded,
              text: _formatDate(task.dueDate),
              color: _getDateColor(task),
            ),
            const SizedBox(width: 8),
            _buildInfoBadge(
              icon: _getPriorityIcon(task.priority),
              text: _getPriorityText(task.priority),
              color: _getPriorityColor(task.priority),
            ),
            if (task.isOverdue) ...[
              const SizedBox(width: 8),
              _buildOverdueBadge(task),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBadge(TaskEntity task) {
    if (task.permanentlyOverdue) {
      return _buildLockedBadge();
    }

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final now = snapshot.data!;
        final graceEnd = task.dueDate.add(const Duration(hours: 24));
        final remaining = graceEnd.difference(now);
        final isExpired = remaining.isNegative;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isExpired ? AppColors.error : AppColors.overdue)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isExpired ? 'LOCKED' : _formatRemainingTime(remaining),
            style: TextStyle(
              fontSize: 10,
              color: isExpired ? AppColors.error : AppColors.overdue,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      );

  // ---------- Logic / Helper Functions ----------

  Future<bool?> _confirmDeleteDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
  }

  void _showCannotCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Locked Task'),
        content: const Text(
          'This task is permanently overdue and cannot be marked as complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium:
        return Icons.linear_scale_rounded;
      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
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

  String _formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) return '00:00:00';
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
