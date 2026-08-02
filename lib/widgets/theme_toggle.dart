import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = context.watch<ThemeProvider>();

    return Semantics(
      label: theme.isDark ? 'Switch to light theme' : 'Switch to dark theme',
      button: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          onPressed: () => context.read<ThemeProvider>().toggle(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              theme.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              key: ValueKey(theme.isDark),
              color: c.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
