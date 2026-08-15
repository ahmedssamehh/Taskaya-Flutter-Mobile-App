import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';

class AnimatedCheckbox extends StatefulWidget {
  const AnimatedCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final VoidCallback onChanged;

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(AnimatedCheckbox old) {
    super.didUpdateWidget(old);
    // Ring only fires on the un-checked -> checked transition, so undoing a
    // completion doesn't celebrate.
    if (widget.checked && !old.checked && !AppMotion.reduced(context)) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);

    return Semantics(
      label: widget.checked ? 'Mark as not done' : 'Mark as done',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onChanged();
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding ring that fades out as the box fills.
                AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) {
                    if (_burst.value == 0 || _burst.isCompleted) {
                      return const SizedBox.shrink();
                    }
                    final t = Curves.easeOutCubic.transform(_burst.value);
                    return Container(
                      width: 21 + 22 * t,
                      height: 21 + 22 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.accent.withValues(alpha: (1 - t) * 0.55),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.checked ? 1 : 0),
                  duration: reduced
                      ? Duration.zero
                      : (widget.checked
                            ? const Duration(milliseconds: 220)
                            : const Duration(milliseconds: 150)),
                  curve: widget.checked
                      ? Curves.easeOutBack
                      : Curves.easeInCubic,
                  builder: (context, t, _) {
                    return Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          Colors.transparent,
                          c.accent,
                          t.clamp(0, 1),
                        ),
                        border: Border.all(color: c.accent, width: 1.75),
                      ),
                      child: t > 0.3
                          ? Icon(Icons.check, size: 13, color: c.onAccent)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
