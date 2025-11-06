// lib/features/tasks/presentation/widgets/form_fields_card.dart
import 'package:flutter/material.dart';
import 'package:todo_app_pro/core/theme/app_colors.dart';
import 'package:todo_app_pro/core/utils/validators.dart';
import 'package:todo_app_pro/features/auth/presentation/widgets/custom_text_feid.dart';

class FormFieldsCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool enabled;

  const FormFieldsCard({
    super.key,
    required this.titleController,
    required this.descriptionController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            CustomTextField(
              controller: titleController,
              label: 'Task Title',
              hint: 'Update task title',
              prefixIcon: Icons.title_outlined,
              validator: (value) => Validators.required(value, 'Title'),
              enabled: enabled,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Update task description',
              prefixIcon: Icons.description_outlined,
              maxLines: 2,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );
  }
}
