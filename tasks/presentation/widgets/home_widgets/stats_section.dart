import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'stats_card.dart';

class StatsSection extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  const StatsSection({
    super.key,
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AnimatedCard(
                  delay: 500,
                  child: StatsCard(
                    title: 'Total',
                    value: total.toString(),
                    icon: Icons.task_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _AnimatedCard(
                  delay: 600,
                  child: StatsCard(
                    title: 'Completed',
                    value: completed.toString(),
                    icon: Icons.check_circle_rounded,
                    color: AppColors.completed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AnimatedCard(
                  delay: 700,
                  child: StatsCard(
                    title: 'Pending',
                    value: pending.toString(),
                    icon: Icons.pending_rounded,
                    color: AppColors.mediumPriority,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _AnimatedCard(
                  delay: 800,
                  child: StatsCard(
                    title: 'Overdue',
                    value: overdue.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.overdue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final int delay;
  final Widget child;

  const _AnimatedCard({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}