import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/tasks/presentation/state/home_page_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/home_widgets/home_app_bar.dart';
import '../widgets/home_widgets/stats_section.dart';
import '../widgets/home_widgets/search_bar_widget.dart';
import '../widgets/home_widgets/filter_tabs.dart';
import '../widgets/home_widgets/task_list_view.dart';
import 'add_task_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController = TextEditingController();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _searchController.addListener(() {
      ref
          .read(homePageNotifierProvider.notifier)
          .updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final homeState = ref.watch(homePageNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) return const Center(child: Text('No user'));

            return tasksAsync.when(
              data: (tasks) => _buildContent(user, tasks, homeState),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskPage()),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Task',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primary,
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildContent(user, List<TaskEntity> tasks, HomePageState state) {
    final filtered = _filterBySearch(tasks, state.searchQuery);
    final stats = _calculateStats(filtered);
    final todayCount = filtered.where((t) => t.dueDate.isToday).length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        HomeAppBar(user: user, onLogout: () => _showLogoutDialog(context)),
        SliverToBoxAdapter(
          child: StatsSection(
            total: filtered.length,
            completed: stats['completed']!,
            pending: stats['pending']!,
            overdue: stats['overdue']!,
          ),
        ),
        SliverToBoxAdapter(
          child: SearchBarWidget(
            controller: _searchController,
            searchQuery: state.searchQuery,
            onClear: () {
              _searchController.clear();
              ref.read(homePageNotifierProvider.notifier).updateSearchQuery('');
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: FilterTabs(
            controller: _tabController,
            totalCount: filtered.length,
            todayCount: todayCount,
            pendingCount: stats['pending']!,
            completedCount: stats['completed']!,
            overdueCount: stats['overdue']!,
            onTap: (i) => ref
                .read(homePageNotifierProvider.notifier)
                .updateSelectedIndex(i),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver:
              TaskListView(tasks: _filterByTab(filtered, state.selectedIndex)),
        ),
      ],
    );
  }

  List<TaskEntity> _filterBySearch(List<TaskEntity> tasks, String query) {
    if (query.isEmpty) return tasks;
    return tasks
        .where((t) =>
            t.title.toLowerCase().contains(query.toLowerCase()) ||
            t.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Map<String, int> _calculateStats(List<TaskEntity> tasks) {
    return {
      'completed': tasks.where((t) => t.isCompleted).length,
      'pending': tasks.where((t) => t.isPending).length,
      'overdue': tasks.where((t) => t.isOverdue).length,
    };
  }

  List<TaskEntity> _filterByTab(List<TaskEntity> tasks, int index) {
    switch (index) {
      case 1:
        return tasks.where((t) => t.dueDate.isToday).toList();
      case 2:
        return tasks.where((t) => t.isPending).toList();
      case 3:
        return tasks.where((t) => t.isCompleted).toList();
      case 4:
        return tasks.where((t) => t.isOverdue).toList();
      default:
        return tasks;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error =
                  await ref.read(authStateNotifierProvider.notifier).signOut();
              if (error != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
