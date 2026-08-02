import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The Taskaya mark: a filled rounded square with a check inside,
/// drawn in the accent color by default (pass [color] to override the
/// fill). The check uses the background color so the mark inverts for
/// free between light and dark themes.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? c.accent,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.check_rounded,
        color: c.background,
        size: size * 0.58,
      ),
    );
  }
}
