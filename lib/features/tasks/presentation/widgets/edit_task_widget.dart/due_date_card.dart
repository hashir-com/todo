// lib/features/tasks/presentation/widgets/due_date_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:todo_app_pro/core/theme/app_colors.dart';

class DueDateCard extends StatelessWidget {
  final VoidCallback onTap;
  final String formattedDate;
  final AnimationController animationController;
  final bool isLoading;
  final Animation<double> fadeAnimation;

  const DueDateCard({
    super.key,
    required this.onTap,
    required this.formattedDate,
    required this.animationController,
    required this.isLoading,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 24),
        child: Card(
          elevation: 10,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onTap,
            splashColor: AppColors.primary.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Hero(
                    tag: 'date-icon', // Simplified tag
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
                          formattedDate,
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
                    progress: animationController,
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
