import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';

/// "Task" at weight 500 + "aya" at weight 400/50% opacity — the only
/// place in the app that mixes weights mid-string.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 24, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base =
        color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final style = AppTextStyles.titleMedium.copyWith(
      fontSize: fontSize,
      color: base,
    );
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(
            text: 'Task',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: 'aya',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: base.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
