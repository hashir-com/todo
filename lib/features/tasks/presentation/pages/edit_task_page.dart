import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/auth/presentation/widgets/custom_text_feid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_state_notifier.dart';
import 'package:shimmer/shimmer.dart'; // Add to pubspec.yaml for shimmer

class EditTaskState {
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
}

class EditTaskNotifier extends StateNotifier<EditTaskState> {
  EditTaskNotifier({
    required DateTime initialDate,
    required TaskPriority initialPriority,
    required bool initialIsCompleted,
  }) : super(EditTaskState(
          selectedDate: initialDate,
          selectedPriority: initialPriority,
          selectedIsCompleted: initialIsCompleted,
        ));

  void updateDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updatePriority(TaskPriority priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  void updateIsCompleted(bool isCompleted) {
    state = state.copyWith(selectedIsCompleted: isCompleted);
  }

  Future<String?> updateTask({
    required TaskEntity originalTask,
    required String title,
    required String description,
    required TaskStateNotifier taskNotifier,
  }) async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    final isLocked = originalTask.status == TaskStatus.overdue &&
        originalTask.permanentlyOverdue;

    TaskStatus newStatus;
    bool newPermOverdue;
    if (isLocked) {
      newStatus = TaskStatus.overdue;
      newPermOverdue = true;
    } else if (state.selectedIsCompleted) {
      newStatus = TaskStatus.completed;
      newPermOverdue = false;
    } else {
      newStatus = state.selectedDate.isBefore(now)
          ? TaskStatus.overdue
          : TaskStatus.pending;
      newPermOverdue = false;
    }

    final updatedTask = originalTask.copyWith(
      title: title.trim(),
      description: description.trim(),
      dueDate: state.selectedDate,
      priority: state.selectedPriority,
      status: newStatus,
      permanentlyOverdue: newPermOverdue,
      updatedAt: DateTime.now(),
    );

    final error = await taskNotifier.updateTask(updatedTask);
    state = state.copyWith(isLoading: false);

    return error;
  }

  Future<String?> deleteTask({
    required String taskId,
    required TaskStateNotifier taskNotifier,
  }) async {
    state = state.copyWith(isLoading: true);
    final error = await taskNotifier.deleteTask(taskId);
    state = state.copyWith(isLoading: false);

    return error;
  }

  Future<String?> toggleTaskStatus({
    required String taskId,
    required TaskStateNotifier taskNotifier,
  }) async {
    state = state.copyWith(isLoading: true);
    final error = await taskNotifier.toggleTaskStatus(taskId);
    state = state.copyWith(isLoading: false);

    if (error == null) {
      // Update local state based on toggle
      state = state.copyWith(selectedIsCompleted: !state.selectedIsCompleted);
    }

    return error;
  }
}

final editTaskNotifierProvider = StateNotifierProvider.autoDispose
    .family<EditTaskNotifier, EditTaskState, TaskEntity>(
  (ref, task) {
    final initialIsCompleted = task.status == TaskStatus.completed;
    return EditTaskNotifier(
      initialDate: task.dueDate,
      initialPriority: task.priority,
      initialIsCompleted: initialIsCompleted,
    );
  },
);

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
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (mounted) {
      // Shimmer success animation
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

    if (shouldDelete != true) return;

    final notifier = ref.read(editTaskNotifierProvider(widget.task).notifier);
    final taskNotifier = ref.read(taskStateNotifierProvider.notifier);

    final error = await notifier.deleteTask(
      taskId: widget.task.id,
      taskNotifier: taskNotifier,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully!'),
          backgroundColor: AppColors.completed,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editTaskNotifierProvider(widget.task));
    final notifier = ref.read(editTaskNotifierProvider(widget.task).notifier);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05), // Responsive padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Toggle Card
                AnimatedContainer(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        'Cannot complete or reschedule',
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
                                  tag: 'status-icon-${widget.task.id}',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        isDuePast
                                            ? 'Due date passed'
                                            : 'On track',
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
                                    onChanged: state.isLoading
                                        ? null
                                        : (value) async {
                                            final taskNotifier = ref.read(
                                                taskStateNotifierProvider
                                                    .notifier);
                                            final error = await taskNotifier
                                                .toggleTaskStatus(
                                                    widget.task.id);
                                            if (error == null) {
                                              notifier.updateIsCompleted(value);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(error),
                                                  backgroundColor:
                                                      AppColors.error,
                                                ),
                                              );
                                            }
                                          },
                                    activeColor: AppColors.completed,
                                    activeTrackColor:
                                        AppColors.completed.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                // Form Fields Card
                Card(
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Title Field
                        CustomTextField(
                          controller: _titleController,
                          label: 'Task Title',
                          hint: 'Update task title',
                          prefixIcon: Icons.title_outlined,
                          validator: (value) =>
                              Validators.required(value, 'Title'),
                          enabled: !state.isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Description Field
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Update task description',
                          prefixIcon: Icons.description_outlined,
                          maxLines: 4,
                          enabled: !state.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Due Date Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 6,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: state.isLoading ? null : _selectDate,
                      splashColor: AppColors.primary.withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.blue.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'date-icon-${widget.task.id}',
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.primary,
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
                                    'Due Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(state.selectedDate),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedIcon(
                              icon: AnimatedIcons.view_list,
                              progress: _animationController,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Priority Card
                Card(
                  elevation: 4,
                  shadowColor: AppColors.mediumPriority.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.amber.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                              child: _PriorityButton(
                                label: 'Low',
                                icon: Icons.keyboard_double_arrow_down_outlined,
                                color: AppColors.lowPriority,
                                isSelected:
                                    state.selectedPriority == TaskPriority.low,
                                onTap: () =>
                                    notifier.updatePriority(TaskPriority.low),
                                enabled: !state.isLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PriorityButton(
                                label: 'Medium',
                                icon: Icons.density_medium_outlined,
                                color: AppColors.mediumPriority,
                                isSelected: state.selectedPriority ==
                                    TaskPriority.medium,
                                onTap: () => notifier
                                    .updatePriority(TaskPriority.medium),
                                enabled: !state.isLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PriorityButton(
                                label: 'High',
                                icon: Icons.keyboard_double_arrow_up_outlined,
                                color: AppColors.highPriority,
                                isSelected:
                                    state.selectedPriority == TaskPriority.high,
                                onTap: () =>
                                    notifier.updatePriority(TaskPriority.high),
                                enabled: !state.isLoading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Update Button with Animation
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Today';
    if (taskDate == tomorrow) return 'Tomorrow';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  const _PriorityButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          splashColor: color.withOpacity(0.2),
          child: Transform.scale(
            scale: isSelected ? 1.05 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? color : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
