import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:todo_app_pro/features/tasks/presentation/state/add_task_state.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/add_task_widgets/add_task_app_bar.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/add_task_widgets/create_task_button.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/add_task_widgets/date_selector_widget.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/add_task_widgets/form_section_widget.dart';
import 'package:todo_app_pro/features/tasks/presentation/widgets/add_task_widgets/priority_selector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../auth/presentation/widgets/custom_text_feid.dart';
import '../providers/task_state_notifier.dart';

class AddTaskPage extends ConsumerStatefulWidget {
  const AddTaskPage({super.key});

  @override
  ConsumerState<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends ConsumerState<AddTaskPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final state = ref.read(addTaskNotifierProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(addTaskNotifierProvider.notifier).updateDate(picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _showSnackBar('User not found', AppColors.error);
      return;
    }

    final error = await ref.read(addTaskNotifierProvider.notifier).createTask(
          title: _titleController.text,
          description: _descriptionController.text,
          taskNotifier: ref.read(taskStateNotifierProvider.notifier),
          userId: user.id,
        );

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error, AppColors.error);
    } else {
      _showSnackBar('Task created successfully!', AppColors.completed);
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.error
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addTaskNotifierProvider);
    final notifier = ref.read(addTaskNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AddTaskAppBar(onClose: () => Navigator.pop(context)),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        FormSection(
                          icon: Icons.title_rounded,
                          iconColor: AppColors.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Task Title',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _titleController,
                                label: '',
                                hint: 'e.g., Complete project proposal',
                                prefixIcon: Icons.edit_note_rounded,
                                validator: (v) =>
                                    Validators.required(v, 'Title'),
                                enabled: !state.isLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FormSection(
                          icon: Icons.description_rounded,
                          iconColor: Colors.blue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _descriptionController,
                                label: '',
                                hint: 'Add details about your task...',
                                prefixIcon: Icons.notes_rounded,
                                maxLines: 4,
                                enabled: !state.isLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FormSection(
                          icon: Icons.calendar_today_rounded,
                          iconColor: Colors.orange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DateSelector(
                                selectedDate: state.selectedDate,
                                onTap: state.isLoading ? null : _selectDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FormSection(
                          icon: Icons.flag_rounded,
                          iconColor: Colors.red,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Priority Level',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              PrioritySelector(
                                selectedPriority: state.selectedPriority,
                                onPriorityChanged: notifier.updatePriority,
                                enabled: !state.isLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        CreateTaskButton(
                          isLoading: state.isLoading,
                          onPressed: _saveTask,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
