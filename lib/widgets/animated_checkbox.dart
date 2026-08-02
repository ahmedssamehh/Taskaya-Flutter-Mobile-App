import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';

class AnimatedCheckbox extends StatelessWidget {
  const AnimatedCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);

    return Semantics(
      label: checked ? 'Mark as not done' : 'Mark as done',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged();
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: checked ? 1 : 0),
              duration: reduced
                  ? Duration.zero
                  : (checked
                        ? const Duration(milliseconds: 220)
                        : const Duration(milliseconds: 150)),
              curve: checked ? Curves.easeOutBack : Curves.easeInCubic,
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
          ),
        ),
      ),
    );
  }
}
