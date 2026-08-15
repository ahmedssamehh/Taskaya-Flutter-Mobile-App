import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/app_motion.dart';
import '../../core/routing/app_routes.dart';
import '../../core/routing/page_transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task.dart';
import '../../data/models/task_category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_mark.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/section_label.dart';
import '../../widgets/staggered_fade_in.dart';
import '../../widgets/task_card.dart';
import '../../widgets/theme_toggle.dart';
import '../../services/local_notification_service.dart';
import '../add_edit/add_edit_task_screen.dart';
import '../focus/focus_setup_screen.dart';
import '../login/login_screen.dart';
import '../welcome/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    LocalNotificationService.instance.requestPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddEdit({Task? task}) async {
    await Navigator.of(
      context,
    ).push(slideUpRoute(AddEditTaskScreen(task: task)));
  }

  Future<void> _openFocus({Task? task}) async {
    await Navigator.of(
      context,
    ).push(slideUpRoute(FocusSetupScreen(initialTask: task)));
  }

  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: "This can't be undone.",
    );
    if (!confirmed || !mounted) return;
    _deleteWithUndo(task);
  }

  void _deleteWithUndo(Task task) {
    final provider = context.read<TaskProvider>();
    provider.deleteTask(task.id).then((error) {
      if (!mounted) return;
      if (error != null) {
        AppToast.error(context, error);
        return;
      }
      AppToast.show(
        context,
        message: 'Task deleted',
        duration: const Duration(seconds: 4),
        actionLabel: 'Undo',
        onAction: () => provider.restoreTask(task),
      );
    });
  }

  Future<void> _toggleComplete(Task task) async {
    final wasCompleted = task.isCompleted;
    final error = await context.read<TaskProvider>().toggleComplete(task.id);
    if (!mounted) return;
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    AppToast.success(
      context,
      wasCompleted ? 'Moved back to pending' : 'Task completed',
    );
  }

  void _showTaskActions(Task task) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!task.isCompleted)
              ListTile(
                leading: Icon(Icons.timer_outlined, color: c.textPrimary),
                title: Text(
                  'Focus on this task',
                  style: AppTextStyles.body.copyWith(color: c.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openFocus(task: task);
                },
              ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: c.textPrimary),
              title: Text(
                'Edit',
                style: AppTextStyles.body.copyWith(color: c.textPrimary),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openAddEdit(task: task);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: c.error),
              title: Text(
                'Delete',
                style: AppTextStyles.body.copyWith(color: c.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(task);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _openAbout() {
    Navigator.of(
      context,
    ).push(fadeRoute(const WelcomeScreen(showsCloseButton: true)));
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You can log back in anytime.',
      confirmLabel: 'Log Out',
      destructive: false,
    );
    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(
        const LoginScreen(),
        settings: const RouteSettings(name: AppRoutes.login),
      ),
      (route) => false,
    );
  }

  Future<bool> _confirmExit() async {
    return showConfirmDialog(
      context,
      title: 'Exit Taskaya?',
      message: 'Are you sure you want to close the app?',
      confirmLabel: 'Exit',
      destructive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tasks = context.watch<TaskProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          bottom: false,
          child: _buildBody(context, tasks),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Start a focus session',
              button: true,
              child: SizedBox(
                width: 48,
                height: 48,
                child: FloatingActionButton(
                  heroTag: 'focusFab',
                  onPressed: () => _openFocus(),
                  backgroundColor: c.surface,
                  foregroundColor: c.textPrimary,
                  elevation: 0,
                  shape: CircleBorder(side: BorderSide(color: c.border)),
                  child: const Icon(Icons.timer_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm2),
            Semantics(
              label: 'Add task',
              button: true,
              child: SizedBox(
                width: 56,
                height: 56,
                child: FloatingActionButton(
                  heroTag: 'addFab',
                  onPressed: () => _openAddEdit(),
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 24),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskProvider tasks) {
    // Genuinely no tasks at all yet (and not loading/erroring) — the big
    // "add your first task" empty state, same as Phase 1.
    if (tasks.isEmpty && !tasks.isLoading && tasks.error == null) {
      return Column(
        children: [
          _Header(tasks: tasks, onInfo: _openAbout, onLogout: _logout),
          _SearchAndFilterBar(searchController: _searchController),
          Expanded(child: EmptyState(onAddTask: () => _openAddEdit())),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(tasks: tasks, onInfo: _openAbout, onLogout: _logout),
        ),
        SliverToBoxAdapter(
          child: _SearchAndFilterBar(searchController: _searchController),
        ),
        if (tasks.error != null)
          SliverToBoxAdapter(child: _ErrorBanner(message: tasks.error!)),
        if (tasks.isLoading && tasks.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tasks.hasNoResultsForFilter)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResultsState(
              onClear: () {
                tasks.clearFilters();
                _searchController.clear();
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.sm,
              AppSpacing.screenPaddingH,
              96,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildSections(tasks)),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSections(TaskProvider tasks) {
    final widgets = <Widget>[];
    final pending = tasks.pending;
    final completed = tasks.completed;
    var index = 0;

    if (pending.isNotEmpty) {
      widgets.add(const SectionLabel(text: 'Pending'));
      widgets.add(const SizedBox(height: AppSpacing.cardGap));
      for (final task in pending) {
        widgets.add(
          StaggeredFadeIn(index: index++, child: _dismissibleCard(task)),
        );
        widgets.add(const SizedBox(height: AppSpacing.cardGap));
      }
    }

    if (completed.isNotEmpty) {
      if (pending.isNotEmpty) {
        widgets.add(
          const SizedBox(height: AppSpacing.sectionGap - AppSpacing.cardGap),
        );
      }
      widgets.add(const SectionLabel(text: 'Completed'));
      widgets.add(const SizedBox(height: AppSpacing.cardGap));
      for (final task in completed) {
        widgets.add(
          StaggeredFadeIn(index: index++, child: _dismissibleCard(task)),
        );
        widgets.add(const SizedBox(height: AppSpacing.cardGap));
      }
    }

    return widgets;
  }

  Widget _dismissibleCard(Task task) {
    final c = context.colors;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: 'Delete task?',
        message: "This can't be undone.",
      ),
      onDismissed: (_) => _deleteWithUndo(task),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.error,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Icon(Icons.delete_outline, color: c.onAccent),
      ),
      child: TaskCard(
        task: task,
        onToggle: () => _toggleComplete(task),
        onTap: () => _openAddEdit(task: task),
        onLongPress: () => _showTaskActions(task),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tasks,
    required this.onInfo,
    required this.onLogout,
  });

  final TaskProvider tasks;
  final VoidCallback onInfo;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppMark(size: 20, color: c.textPrimary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Taskaya',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: c.textPrimary,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${tasks.pendingCount} pending · ${tasks.completedCount} done',
                  style: AppTextStyles.meta.copyWith(
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(),
          const ThemeToggle(),
          Semantics(
            label: 'About Taskaya',
            button: true,
            child: IconButton(
              onPressed: onInfo,
              icon: Icon(Icons.info_outline, color: c.textPrimary, size: 20),
            ),
          ),
          Semantics(
            label: 'Log out',
            button: true,
            child: IconButton(
              onPressed: onLogout,
              icon: Icon(Icons.logout_outlined, color: c.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tasks = context.watch<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.sm2,
        AppSpacing.screenPaddingH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            textField: true,
            label: 'Search tasks',
            child: TextField(
              controller: searchController,
              onChanged: tasks.setQuery,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search tasks',
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: c.textSecondary,
                ),
                suffixIcon: tasks.query.isEmpty
                    ? null
                    : Semantics(
                        label: 'Clear search',
                        button: true,
                        child: IconButton(
                          icon: Icon(Icons.close, size: 16, color: c.textSecondary),
                          onPressed: () {
                            searchController.clear();
                            tasks.clearQuery();
                          },
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 34,
            child: Row(
              children: TaskStatusFilter.values.map((filter) {
                final selected = tasks.statusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterChip(
                    label: switch (filter) {
                      TaskStatusFilter.all => 'All',
                      TaskStatusFilter.pending => 'Pending',
                      TaskStatusFilter.completed => 'Completed',
                    },
                    selected: selected,
                    onTap: () => tasks.setStatusFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Category filters scroll horizontally so all four fit on narrow
          // screens alongside the "All" reset chip.
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _FilterChip(
                  label: 'All categories',
                  selected: tasks.categoryFilter == null,
                  onTap: () => tasks.setCategoryFilter(null),
                ),
                const SizedBox(width: AppSpacing.sm),
                ...TaskCategory.values.map((cat) {
                  final count = tasks.countForCategory(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChip(
                      label: '${cat.label} ($count)',
                      icon: cat.icon,
                      selected: tasks.categoryFilter == cat,
                      onTap: () => tasks.setCategoryFilter(
                        tasks.categoryFilter == cat ? null : cat,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onAccent : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: AnimatedContainer(
            duration: AppMotion.d(context, AppMotion.fast),
            curve: AppMotion.enter,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? c.accent : c.border),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 44, color: c.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No matching tasks',
              style: AppTextStyles.taskTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search or filter.',
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear search & filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
        AppSpacing.screenPaddingH,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm2),
        decoration: BoxDecoration(
          border: Border.all(color: c.error),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, size: 18, color: c.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.meta.copyWith(color: c.error),
              ),
            ),
            Semantics(
              label: 'Dismiss error',
              button: true,
              child: IconButton(
                icon: Icon(Icons.close, size: 16, color: c.error),
                onPressed: () => context.read<TaskProvider>().clearError(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
