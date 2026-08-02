import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/task.dart';
import '../../data/models/task_priority.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_text_field.dart';
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
  DateTime? _dueDate;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _priority = task?.priority ?? TaskPriority.medium;
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

  void _save() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final provider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (widget.isEditMode) {
      provider.updateTask(
        widget.task!.copyWith(
          title: title,
          description: description,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        ),
      );
    } else {
      provider.addTask(
        title: title,
        description: description,
        priority: _priority,
        dueDate: _dueDate,
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: "This can't be undone.",
    );
    if (!confirmed || !mounted) return;
    context.read<TaskProvider>().deleteTask(widget.task!.id);
    if (mounted) Navigator.of(context).pop();
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
                    maxLength: 60,
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
                    textInputAction: TextInputAction.newline,
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
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: widget.isEditMode ? 'Save Changes' : 'Save Task',
                    onPressed: _save,
                  ),
                  if (widget.isEditMode) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: c.border),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: TextButton(
                        onPressed: _delete,
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
