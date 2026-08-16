import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/page_transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_fade_in.dart';
import 'focus_timer_screen.dart';

/// Step one of Focus Mode: pick the task to work on and how long to focus.
class FocusSetupScreen extends StatefulWidget {
  const FocusSetupScreen({super.key, this.initialTask});

  /// Pre-selects a task when Focus is launched from a specific task's
  /// action sheet rather than the Home shortcut.
  final Task? initialTask;

  @override
  State<FocusSetupScreen> createState() => _FocusSetupScreenState();
}

class _FocusSetupScreenState extends State<FocusSetupScreen> {
  /// The 5-second "Test" entry is a deliberate short option for trying the
  /// end-of-session flow without waiting out a full sprint.
  static const _testDuration = Duration(seconds: 5);
  static const _presets = <Duration>[
    _testDuration,
    Duration(minutes: 15),
    Duration(minutes: 25),
    Duration(minutes: 45),
    Duration(minutes: 60),
  ];

  Task? _selected;
  Duration _duration = const Duration(minutes: 25);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTask;
  }

  void _start() {
    final task = _selected;
    if (task == null) return;
    Navigator.of(context).pushReplacement(
      slideUpRoute(FocusTimerScreen(task: task, duration: _duration)),
    );
  }

  static String _durationLabel(Duration d) => d == _testDuration
      ? 'Test'
      : d.inMinutes >= 1
      ? '${d.inMinutes}-minute'
      : '${d.inSeconds}-second';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Only pending tasks are worth focusing on.
    final tasks = context.watch<TaskProvider>().allPending;

    // A pre-selected task may have been completed/deleted elsewhere.
    if (_selected != null && !tasks.any((t) => t.id == _selected!.id)) {
      _selected = null;
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        leading: Semantics(
          label: 'Close',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Focus'),
      ),
      body: SafeArea(
        child: tasks.isEmpty
            ? _EmptyFocusState()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPaddingH,
                        AppSpacing.md,
                        AppSpacing.screenPaddingH,
                        AppSpacing.md,
                      ),
                      children: [
                        Text(
                          'How long?',
                          style: AppTextStyles.label.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: _presets.map((d) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: d == _presets.last
                                      ? 0
                                      : AppSpacing.xs,
                                ),
                                child: _DurationChip(
                                  duration: d,
                                  selected: d == _duration,
                                  onTap: () => setState(() => _duration = d),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        Text(
                          'Which task?',
                          style: AppTextStyles.label.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < tasks.length; i++)
                          StaggeredFadeIn(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.cardGap,
                              ),
                              child: _SelectableTask(
                                task: tasks[i],
                                selected: _selected?.id == tasks[i].id,
                                onTap: () =>
                                    setState(() => _selected = tasks[i]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingH,
                      0,
                      AppSpacing.screenPaddingH,
                      AppSpacing.md,
                    ),
                    child: PrimaryButton(
                      label: _selected == null
                          ? 'Select a task to start'
                          : 'Start ${_durationLabel(_duration)} session',
                      onPressed: _selected == null ? null : _start,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyFocusState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 48, color: c.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nothing to focus on',
              style: AppTextStyles.taskTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add a task first, then come back to start a focus session.',
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final Duration duration;
  final bool selected;
  final VoidCallback onTap;

  /// The short debug preset gets its own "Test" label instead of a raw
  /// second count, so it doesn't read like a real focus-length option.
  bool get _isTest => duration == _FocusSetupScreenState._testDuration;
  bool get _isSeconds => duration.inMinutes < 1;
  String get _value =>
      _isTest ? 'Test' : (_isSeconds ? '${duration.inSeconds}' : '${duration.inMinutes}');
  String get _unit =>
      _isTest ? '${duration.inSeconds}s' : (_isSeconds ? 'sec' : 'min');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: _isTest
          ? 'Test, ${duration.inSeconds} seconds'
          : _isSeconds
          ? '${duration.inSeconds} seconds'
          : '${duration.inMinutes} minutes',
      child: Material(
        color: selected ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: selected ? c.accent : c.border),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _value,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: _isTest ? 14 : 17,
                    color: selected ? c.onAccent : c.textPrimary,
                  ),
                ),
                Text(
                  _unit,
                  style: AppTextStyles.meta.copyWith(
                    fontSize: 10.5,
                    color: selected ? c.onAccent : c.textSecondary,
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

class _SelectableTask extends StatelessWidget {
  const _SelectableTask({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final Task task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: task.title,
      child: Material(
        color: selected ? c.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm2),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? c.borderStrong : c.border,
                width: selected ? 1.5 : AppSpacing.borderHairline,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? c.textPrimary : c.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.taskTitle.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            task.category.icon,
                            size: 12,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.category.label,
                            style: AppTextStyles.meta.copyWith(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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
