import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/page_transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_mark.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/staggered_fade_in.dart';
import '../../widgets/task_card.dart';
import '../../widgets/theme_toggle.dart';
import '../add_edit/add_edit_task_screen.dart';
import '../welcome/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openAddEdit({Task? task}) async {
    await Navigator.of(
      context,
    ).push(slideUpRoute(AddEditTaskScreen(task: task)));
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
    final allBefore = [...provider.pending, ...provider.completed];
    final index = allBefore.indexWhere((t) => t.id == task.id);
    provider.deleteTask(task.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.restoreTask(task, index < 0 ? 0 : index),
        ),
      ),
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

  Future<bool> _confirmExit() async {
    return showConfirmDialog(
      context,
      title: 'Exit Taskaya?',
      message: 'Are you sure you want to close the app?',
      confirmLabel: 'Exit',
      destructive: false,
    );
  }

  void _showVoiceComingSoon() {
    final c = context.colors;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic_outlined, color: c.onAccent, size: 18),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Voice input is coming soon')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
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
          child: tasks.isEmpty
              ? Column(
                  children: [
                    _Header(
                      pendingCount: tasks.pendingCount,
                      completedCount: tasks.completedCount,
                      onInfo: _openAbout,
                    ),
                    Expanded(
                      child: EmptyState(onAddTask: () => _openAddEdit()),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        pendingCount: tasks.pendingCount,
                        completedCount: tasks.completedCount,
                        onInfo: _openAbout,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPaddingH,
                        AppSpacing.sm,
                        AppSpacing.screenPaddingH,
                        96,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          _buildSections(tasks),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Add task by voice, coming soon',
              button: true,
              child: SizedBox(
                width: 44,
                height: 44,
                child: FloatingActionButton(
                  heroTag: 'voiceFab',
                  onPressed: _showVoiceComingSoon,
                  backgroundColor: c.surface,
                  foregroundColor: c.textPrimary,
                  elevation: 0,
                  shape: CircleBorder(side: BorderSide(color: c.border)),
                  child: const Icon(Icons.mic_none_outlined, size: 18),
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
        onToggle: () => context.read<TaskProvider>().toggleComplete(task.id),
        onTap: () => _openAddEdit(task: task),
        onLongPress: () => _showTaskActions(task),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pendingCount,
    required this.completedCount,
    required this.onInfo,
  });

  final int pendingCount;
  final int completedCount;
  final VoidCallback onInfo;

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
                  '$pendingCount pending · $completedCount done',
                  style: AppTextStyles.meta.copyWith(
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const ThemeToggle(),
          Semantics(
            label: 'About Taskaya',
            button: true,
            child: IconButton(
              onPressed: onInfo,
              icon: Icon(Icons.info_outline, color: c.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
