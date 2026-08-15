import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'primary_button.dart';

/// Full-screen "you did it" moment shown after a focus session is completed.
///
/// Everything is drawn with [CustomPainter] and staggered [Animation]s rather
/// than a Lottie/Rive asset, so the celebration stays self-contained and
/// respects the app's monochrome design language.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.dismissLabel = 'Done',
  });

  final String title;
  final String message;
  final VoidCallback onDismiss;
  final String dismissLabel;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _burst;
  late final AnimationController _badge;

  late final Animation<double> _badgeScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;
  late final Animation<double> _checkDraw;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    _badge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Springy "pop" for the badge, then a ring that expands and fades,
    // then the checkmark draws itself, then the copy slides up.
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.12).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(parent: _badge, curve: const Interval(0.0, 0.45)),
    );

    _ringScale = Tween(begin: 0.6, end: 1.8).animate(
      CurvedAnimation(
        parent: _badge,
        curve: const Interval(0.05, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _ringFade = Tween(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _badge, curve: const Interval(0.05, 0.5)),
    );

    _checkDraw = CurvedAnimation(
      parent: _badge,
      curve: const Interval(0.3, 0.62, curve: Curves.easeOutCubic),
    );

    _textFade = CurvedAnimation(
      parent: _badge,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    );
    _textSlide = Tween(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _badge,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
      ),
    );

  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery isn't safe to read in initState, so the reduced-motion
    // check (and the animation kickoff) happens here instead.
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _badge.value = 1;
      _burst.value = 1;
    } else {
      _badge.forward();
      _burst.forward();
    }
  }

  @override
  void dispose() {
    _badge.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: c.background,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti fills the whole screen behind the badge.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _burst.value,
                    color: c.textPrimary,
                    accent: c.textSecondary,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: AnimatedBuilder(
                    animation: _badge,
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Opacity(
                              opacity: _ringFade.value.clamp(0.0, 1.0),
                              child: Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c.textPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _badgeScale.value.clamp(0.0, 2.0),
                            child: Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                              ),
                              child: CustomPaint(
                                painter: _CheckPainter(
                                  progress: _checkDraw.value,
                                  color: c.onAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AnimatedBuilder(
                  animation: _badge,
                  builder: (context, child) => Opacity(
                    opacity: _textFade.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
                  child: AnimatedBuilder(
                    animation: _badge,
                    builder: (context, child) => Opacity(
                      opacity: _textFade.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                    child: PrimaryButton(
                      label: widget.dismissLabel,
                      onPressed: widget.onDismiss,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the checkmark stroke progressively so it appears to be written.
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final start = Offset(w * 0.28, h * 0.52);
    final mid = Offset(w * 0.44, h * 0.68);
    final end = Offset(w * 0.73, h * 0.35);

    final path = Path()..moveTo(start.dx, start.dy);
    // First leg of the tick, then the long upstroke.
    if (progress <= 0.5) {
      final t = progress / 0.5;
      path.lineTo(
        start.dx + (mid.dx - start.dx) * t,
        start.dy + (mid.dy - start.dy) * t,
      );
    } else {
      final t = (progress - 0.5) / 0.5;
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(
        mid.dx + (end.dx - mid.dx) * t,
        mid.dy + (end.dy - mid.dy) * t,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

/// Monochrome confetti: each piece gets a deterministic trajectory from a
/// seeded RNG so the burst looks scattered but never re-randomizes on
/// rebuild.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  final double progress;
  final Color color;
  final Color accent;

  static const _count = 46;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final rng = math.Random(7);
    final origin = Offset(size.width / 2, size.height * 0.42);

    for (var i = 0; i < _count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 90 + rng.nextDouble() * 230;
      final spin = (rng.nextDouble() - 0.5) * 10;
      final isBar = rng.nextBool();
      final pieceColor = rng.nextBool() ? color : accent;

      // Ballistic path: outward velocity plus gravity, fading near the end.
      final t = progress;
      final dx = math.cos(angle) * speed * t;
      final dy = math.sin(angle) * speed * t + 520 * t * t;
      final pos = origin + Offset(dx, dy);

      final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      final paint = Paint()
        ..color = pieceColor.withValues(alpha: fade.clamp(0.0, 1.0) * 0.9);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(spin * t);
      if (isBar) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 8, height: 3.5),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 3, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
