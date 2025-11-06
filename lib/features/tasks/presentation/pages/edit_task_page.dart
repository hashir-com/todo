// lib/features/tasks/presentation/pages/edit_task_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todo_app_pro/features/auth/presentation/widgets/custom_button.dart';
import 'package:todo_app_pro/features/tasks/domain/entities/task_entity.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/edit_task_widget.dart/due_date_card.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/edit_task_widget.dart/form_fields_card.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/edit_task_widget.dart/priority_card.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/edit_task_widget.dart/status_toggle_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/edit_task_notifier.dart';
import '../providers/task_state_notifier.dart';

class EditTaskPage extends ConsumerStatefulWidget {
  final TaskEntity task;

  const EditTaskPage({super.key, required this.task});

  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final state = ref.read(editTaskNotifierProvider(widget.task));
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(editTaskNotifierProvider(widget.task).notifier)
          .updateDate(picked);
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(editTaskNotifierProvider(widget.task).notifier);
    final taskNotifier = ref.read(taskStateNotifierProvider.notifier);

    final error = await notifier.updateTask(
      originalTask: widget.task,
      title: _titleController.text,
      description: _descriptionController.text,
      taskNotifier: taskNotifier,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Shimmer.fromColors(
            baseColor: AppColors.completed,
            highlightColor: Colors.white,
            period: const Duration(milliseconds: 1000),
            child: const Text('Task updated successfully!'),
          ),
          backgroundColor: AppColors.completed,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTask() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final notifier = ref.read(editTaskNotifierProvider(widget.task).notifier);
    final taskNotifier = ref.read(taskStateNotifierProvider.notifier);

    final error = await notifier.deleteTask(
      taskId: widget.task.id,
      taskNotifier: taskNotifier,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Task deleted successfully!'),
            backgroundColor: AppColors.completed),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editTaskNotifierProvider(widget.task));
    final now = DateTime.now();
    final isLocked = widget.task.status == TaskStatus.overdue &&
        widget.task.permanentlyOverdue;
    final switchValue = state.selectedIsCompleted;
    final isDuePast = state.selectedDate.isBefore(now);

    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (switchValue) {
      statusColor = AppColors.completed;
      statusIcon = Icons.check_circle;
      statusText = 'Task Completed';
    } else if (isDuePast) {
      statusColor = AppColors.overdue;
      statusIcon = Icons.warning;
      statusText = 'Task Overdue';
    } else {
      statusColor = AppColors.pending ?? Colors.grey;
      statusIcon = Icons.pending;
      statusText = 'Task Pending';
    }

    final formattedDate = _formatDate(state.selectedDate, now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task',
            style: TextStyle(
                color: AppColors.background, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          AnimatedScale(
            scale: state.isLoading ? 0.8 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 24),
              tooltip: 'Delete Task',
              onPressed: state.isLoading ? null : _deleteTask,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusToggleCard(
                  task: widget.task,
                  isLocked: isLocked,
                  statusColor: statusColor,
                  statusIcon: statusIcon,
                  statusText: statusText,
                  isDuePast: isDuePast,
                  switchValue: switchValue,
                  isLoading: state.isLoading,
                ),
                FormFieldsCard(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: 24),
                DueDateCard(
                  onTap: _selectDate,
                  formattedDate: formattedDate,
                  animationController: _animationController,
                  isLoading: state.isLoading,
                  fadeAnimation: _fadeAnimation,
                ),
                PriorityCard(task: widget.task, isLoading: state.isLoading),
                const SizedBox(height: 40),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: CustomButton(
                    text: 'Update Task',
                    onPressed: state.isLoading ? null : _updateTask,
                    isLoading: state.isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Today';
    if (taskDate == tomorrow) return 'Tomorrow';

    return '${date.day}/${date.month}/${date.year}';
  }
}
