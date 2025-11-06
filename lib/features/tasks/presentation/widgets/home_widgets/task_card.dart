// ignore_for_file: deprecated_member_use

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

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
          margin: EdgeInsets.only(
            bottom: 12,
            left: screenWidth * 0.02,
            right: screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _getPriorityColor(task.priority).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getPriorityColor(task.priority).withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckbox(context, ref, isCompact),
              SizedBox(width: isCompact ? 8 : 10),
              Expanded(child: _buildTaskContent(context, ref, isCompact)),
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
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      );

  Widget _buildCheckbox(BuildContext context, WidgetRef ref, bool isCompact) {
    final size = isCompact ? 22.0 : 26.0;

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
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                task.isCompleted ? AppColors.completed : Colors.grey.shade400,
            width: 2.5,
          ),
          color: task.isCompleted ? AppColors.completed : Colors.transparent,
          boxShadow: task.isCompleted
              ? [
                  BoxShadow(
                    color: AppColors.completed.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: task.isCompleted
            ? Icon(
                Icons.check_rounded,
                size: isCompact ? 14 : 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildTaskContent(
      BuildContext context, WidgetRef ref, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          task.title,
          style: TextStyle(
            fontSize: isCompact ? 15 : 16.5,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Description
        if (task.description.isNotEmpty) ...[
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 12.5 : 13.5,
              color: Colors.grey[600],
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              height: 1.4,
            ),
          ),
        ],

        SizedBox(height: isCompact ? 8 : 12),

        // Bottom Row - Responsive Wrap
        Wrap(
          spacing: isCompact ? 6 : 8,
          runSpacing: isCompact ? 6 : 8,
          children: [
            _buildInfoBadge(
              icon: Icons.calendar_today_rounded,
              text: _formatDate(task.dueDate),
              color: _getDateColor(task),
              isCompact: isCompact,
            ),
            _buildInfoBadge(
              icon: _getPriorityIcon(task.priority),
              text: _getPriorityText(task.priority),
              color: _getPriorityColor(task.priority),
              isCompact: isCompact,
            ),
            if (task.isOverdue) _buildOverdueBadge(task, isCompact),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.9),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 14, color: Colors.white),
          SizedBox(width: isCompact ? 4 : 5),
          Text(
            text,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBadge(TaskEntity task, bool isCompact) {
    if (task.permanentlyOverdue) {
      return _buildLockedBadge(isCompact);
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
        final badgeColor = isExpired ? AppColors.error : AppColors.overdue;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeColor.withOpacity(0.9),
                badgeColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpired ? Icons.lock_rounded : Icons.timer_rounded,
                size: isCompact ? 11 : 12,
                color: Colors.white,
              ),
              SizedBox(width: isCompact ? 3 : 4),
              Text(
                isExpired ? 'LOCKED' : _formatRemainingTime(remaining),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedBadge(bool isCompact) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(0.9),
              AppColors.error,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              size: isCompact ? 11 : 12,
              color: Colors.white,
            ),
            SizedBox(width: isCompact ? 3 : 4),
            Text(
              'LOCKED',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

  // ---------- Logic / Helper Functions ----------

  Future<bool?> _confirmDeleteDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    return Colors.grey.shade700;
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
