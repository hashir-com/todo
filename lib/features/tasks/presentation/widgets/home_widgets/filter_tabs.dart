import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class FilterTabs extends StatelessWidget {
  final TabController controller;
  final int totalCount;
  final int todayCount;
  final int pendingCount;
  final int completedCount;
  final int overdueCount;
  final Function(int) onTap;

  const FilterTabs({
    super.key,
    required this.controller,
    required this.totalCount,
    required this.todayCount,
    required this.pendingCount,
    required this.completedCount,
    required this.overdueCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(6),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(6),
        onTap: onTap,
        tabs: [
          _buildTab('All ($totalCount)'),
          _buildTab('Today ($todayCount)'),
          _buildTab('Pending ($pendingCount)'),
          _buildTab('Completed ($completedCount)'),
          _buildTab('Overdue ($overdueCount)'),
        ],
      ),
    );
  }

  Tab _buildTab(String text) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text),
      ),
    );
  }
}