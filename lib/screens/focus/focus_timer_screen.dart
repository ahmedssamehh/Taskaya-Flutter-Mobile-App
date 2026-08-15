import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task.dart';
import '../../providers/task_provider.dart';
import '../../services/local_notification_service.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

/// Step two of Focus Mode: a full-screen countdown for a single task.
///
/// When the timer reaches zero the user is asked whether they finished; a
/// yes marks the task complete and plays the celebration, a no offers extra
/// time or an exit.
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({
    super.key,
    required this.task,
    required this.duration,
  });

  final Task task;
  final Duration duration;

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  late Duration _total;
  late Duration _remaining;
  Timer? _ticker;
  bool _paused = false;
  bool _finished = false;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _total = widget.duration;
    _remaining = widget.duration;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _finished) return;
      setState(() {
        final next = _remaining - const Duration(seconds: 1);
        _remaining = next.isNegative ? Duration.zero : next;
      });
      if (_remaining == Duration.zero) _onTimeUp();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onTimeUp() async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _pulse.stop();

    // Fires even if the app is backgrounded, which is the common case for a
    // focus session.
    unawaited(
      LocalNotificationService.instance.showNow(
        sessionId: 'focus-${widget.task.id}',
        title: 'Focus session complete',
        body: 'Time is up for "${widget.task.title}". Did you finish it?',
      ),
    );

    if (!mounted) return;
    await _askIfCompleted();
  }

  Future<void> _askIfCompleted() async {
    final choice = await showModalBottomSheet<_FocusOutcome>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (sheetContext) => _TimeUpSheet(task: widget.task),
    );
    if (!mounted) return;

    switch (choice) {
      case _FocusOutcome.completed:
        await _completeTask();
      case _FocusOutcome.addFive:
        _extend(const Duration(minutes: 5));
      case _FocusOutcome.addTen:
        _extend(const Duration(minutes: 10));
      case _FocusOutcome.addFifteen:
        _extend(const Duration(minutes: 15));
      case _FocusOutcome.exit:
      case null:
        if (mounted) Navigator.of(context).pop();
    }
  }

  void _extend(Duration extra) {
    setState(() {
      _finished = false;
      _paused = false;
      _total = _total + extra;
      _remaining = extra;
    });
    _pulse.repeat(reverse: true);
    _startTicker();
    AppToast.show(
      context,
      message: 'Added ${extra.inMinutes} more minutes',
    );
  }

  Future<void> _completeTask() async {
    final provider = context.read<TaskProvider>();
    final error = await provider.toggleComplete(widget.task.id);
    if (!mounted) return;
    if (error != null) {
      AppToast.error(context, error);
      Navigator.of(context).pop();
      return;
    }
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: AppMotion.d(context, AppMotion.screen),
        pageBuilder: (context, _, _) => CelebrationOverlay(
          title: 'Nice work!',
          message:
              '"${widget.task.title}" is done.\n'
              'You focused for ${_formatTotal(_total)}.',
          dismissLabel: 'Back to tasks',
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmQuit() async {
    final leave = await showConfirmDialog(
      context,
      title: 'End focus session?',
      message: 'Your progress in this session will be lost.',
      confirmLabel: 'End Session',
      destructive: false,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  static String _formatTotal(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return m == 0 ? '${h}h' : '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds}s';
  }

  String get _clock {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = _remaining.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  double get _progress {
    if (_total.inSeconds == 0) return 0;
    return 1 - (_remaining.inSeconds / _total.inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  label: 'End focus session',
                  button: true,
                  child: IconButton(
                    icon: Icon(Icons.close, color: c.textPrimary),
                    onPressed: _confirmQuit,
                  ),
                ),
              ),
              const Spacer(),
              // Breathing ring + progress arc + clock.
              SizedBox(
                width: 280,
                height: 280,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final breathe = _paused
                        ? 0.0
                        : math.sin(_pulse.value * math.pi) * 0.03;
                    return Transform.scale(
                      scale: 1 + breathe,
                      child: CustomPaint(
                        painter: _FocusRingPainter(
                          progress: _progress,
                          trackColor: c.border,
                          progressColor: c.textPrimary,
                          glowColor: c.textPrimary.withValues(alpha: 0.08),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _clock,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: c.textPrimary,
                            fontSize: 56,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _paused ? 'Paused' : 'Stay with it',
                          style: AppTextStyles.meta.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Text(
                      'Focusing on',
                      style: AppTextStyles.meta.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.task.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: c.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: _paused ? 'Resume' : 'Pause',
                      onPressed: () => setState(() {
                        _paused = !_paused;
                        if (_paused) {
                          _pulse.stop();
                        } else {
                          _pulse.repeat(reverse: true);
                        }
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      label: 'I finished early',
                      outlined: true,
                      onPressed: () {
                        _finished = true;
                        _ticker?.cancel();
                        _completeTask();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FocusOutcome { completed, addFive, addTen, addFifteen, exit }

class _TimeUpSheet extends StatelessWidget {
  const _TimeUpSheet({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  size: 26,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Time's up",
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: c.textPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Did you finish "${task.title}"?',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Yes, mark it done',
              onPressed: () =>
                  Navigator.of(context).pop(_FocusOutcome.completed),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Need more time?',
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(color: c.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MoreTimeButton(
                    label: '+5 min',
                    onTap: () =>
                        Navigator.of(context).pop(_FocusOutcome.addFive),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoreTimeButton(
                    label: '+10 min',
                    onTap: () =>
                        Navigator.of(context).pop(_FocusOutcome.addTen),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoreTimeButton(
                    label: '+15 min',
                    onTap: () =>
                        Navigator.of(context).pop(_FocusOutcome.addFifteen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_FocusOutcome.exit),
                child: Text(
                  'Exit focus mode',
                  style: AppTextStyles.button.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTimeButton extends StatelessWidget {
  const _MoreTimeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: c.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Track + progress arc + soft inner glow for the countdown ring.
class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.glowColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 14;

    canvas.drawCircle(center, radius, Paint()..color = glowColor);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6,
      );
    }
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
