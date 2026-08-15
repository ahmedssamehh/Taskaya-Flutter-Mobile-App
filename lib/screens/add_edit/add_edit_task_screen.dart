import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/reminder_offset.dart';
import '../../data/models/task.dart';
import '../../data/models/task_category.dart';
import '../../data/models/task_priority.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/monochrome_picker_theme.dart';
import '../../widgets/primary_button.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, this.task});

  final Task? task;

  bool get isEditMode => task != null;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late TaskCategory _category;
  late ReminderOffset _reminder;
  DateTime? _dueDate;
  bool _dirty = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? TaskCategory.personal;
    _reminder = task?.reminderOffset ?? ReminderOffset.atDueTime;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: monochromePickerBuilder,
    );
    if (picked == null) return;

    final existingTime = _dueDate;
    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        existingTime?.hour ?? 0,
        existingTime?.minute ?? 0,
      );
    });
    _markDirty();
  }

  Future<void> _pickTime() async {
    final base = _dueDate ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      builder: monochromePickerBuilder,
    );
    if (picked == null) return;

    setState(() {
      final d = _dueDate ?? DateTime.now();
      _dueDate = DateTime(d.year, d.month, d.day, picked.hour, picked.minute);
    });
    _markDirty();
  }

  void _clearDate() {
    setState(() => _dueDate = null);
    _markDirty();
  }

  Future<void> _save() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _submitting = true);
    final provider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final error = widget.isEditMode
        ? await provider.updateTask(
            widget.task!.copyWith(
              title: title,
              description: description,
              priority: _priority,
              category: _category,
              dueDate: _dueDate,
              clearDueDate: _dueDate == null,
              reminderOffset: _reminder,
            ),
          )
        : await provider.addTask(
            title: title,
            description: description,
            priority: _priority,
            category: _category,
            dueDate: _dueDate,
            reminderOffset: _reminder,
          );

    if (!mounted) return;
    if (error != null) {
      setState(() => _submitting = false);
      AppToast.error(context, error);
      return;
    }
    final wasEdit = widget.isEditMode;
    Navigator.of(context).pop();
    AppToast.success(
      context,
      wasEdit ? 'Task updated' : 'Task "${_shortTitle(title)}" created',
    );
  }

  /// Keeps toast copy short when a task has a long title.
  String _shortTitle(String title) =>
      title.length <= 24 ? title : '${title.substring(0, 24)}…';

  Future<void> _delete() async {
    if (_submitting) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: "This can't be undone.",
    );
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    final provider = context.read<TaskProvider>();
    final deleted = widget.task!;
    final error = await provider.deleteTask(deleted.id);
    if (!mounted) return;
    if (error != null) {
      setState(() => _submitting = false);
      AppToast.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppToast.show(
      context,
      message: 'Task deleted',
      actionLabel: 'Undo',
      onAction: () => provider.restoreTask(deleted),
    );
  }

  Future<void> _close() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: 'Your edits will be lost.',
      confirmLabel: 'Discard',
    );
    if (discard && mounted) Navigator.of(context).pop();
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

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _close();
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          leading: Semantics(
            label: 'Close',
            button: true,
            child: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          ),
          title: Text(widget.isEditMode ? 'Edit Task' : 'New Task'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.md,
              AppSpacing.screenPaddingH,
              AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              onChanged: _markDirty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Title',
                    controller: _titleController,
                    autofocus: !widget.isEditMode,
                    maxLength: Validators.maxTitleLength,
                    textInputAction: TextInputAction.next,
                    validator: Validators.requiredTitle,
                    trailingIcon: Icons.mic_none_outlined,
                    trailingLabel: 'Add title by voice, coming soon',
                    onTrailingTap: _showVoiceComingSoon,
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  AppTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: Validators.maxDescriptionLength,
                    textInputAction: TextInputAction.newline,
                    validator: Validators.description,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Priority',
                    style: AppTextStyles.label.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final selected = p == _priority;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: p != TaskPriority.values.last
                                ? AppSpacing.sm
                                : 0,
                          ),
                          child: _PriorityChip(
                            label: p.label,
                            selected: selected,
                            onTap: () {
                              setState(() => _priority = p);
                              _markDirty();
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Category',
                    style: AppTextStyles.label.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: TaskCategory.values.map((cat) {
                      final selected = cat == _category;
                      return _ChoiceChip(
                        label: cat.label,
                        icon: cat.icon,
                        selected: selected,
                        onTap: () {
                          setState(() => _category = cat);
                          _markDirty();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Due',
                    style: AppTextStyles.label.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _OutlinedTile(
                          icon: Icons.calendar_today_outlined,
                          label: _dueDate == null
                              ? 'Select date'
                              : DateFormatter.relativeDate(_dueDate!),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _OutlinedTile(
                          icon: Icons.access_time_outlined,
                          label: _dueDate == null
                              ? 'Select time'
                              : DateFormatter.time(_dueDate!),
                          onTap: _pickTime,
                        ),
                      ),
                      if (_dueDate != null)
                        Semantics(
                          label: 'Clear due date',
                          button: true,
                          child: IconButton(
                            onPressed: _clearDate,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Row(
                    children: [
                      Text(
                        'Remind me',
                        style: AppTextStyles.label.copyWith(
                          color: _dueDate == null
                              ? c.textTertiary
                              : c.textPrimary,
                        ),
                      ),
                      if (_dueDate == null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '— set a due date first',
                            style: AppTextStyles.meta.copyWith(
                              color: c.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Opacity(
                    opacity: _dueDate == null ? 0.45 : 1,
                    child: IgnorePointer(
                      ignoring: _dueDate == null,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: ReminderOffset.values.map((r) {
                          return _ChoiceChip(
                            label: r.label,
                            icon: r == ReminderOffset.none
                                ? Icons.notifications_off_outlined
                                : Icons.notifications_active_outlined,
                            selected: r == _reminder,
                            onTap: () {
                              setState(() => _reminder = r);
                              _markDirty();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: widget.isEditMode ? 'Save Changes' : 'Save Task',
                    onPressed: _submitting ? null : _save,
                    isLoading: _submitting,
                  ),
                  if (widget.isEditMode) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: c.border),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: TextButton(
                        onPressed: _submitting ? null : _delete,
                        child: Text(
                          'Delete task',
                          style: AppTextStyles.button.copyWith(color: c.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: selected ? c.accent : c.border),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: selected ? c.onAccent : c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared pill used by both the category and reminder pickers.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? c.accent : c.border),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? c.onAccent : c.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: selected ? c.onAccent : c.textPrimary,
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

class _OutlinedTile extends StatelessWidget {
  const _OutlinedTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.meta.copyWith(
                    color: c.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
