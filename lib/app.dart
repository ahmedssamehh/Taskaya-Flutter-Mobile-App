import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

/// Lets code outside the widget tree (the local-notification tap handler
/// in `main.dart`) push routes — e.g. opening a task when its reminder
/// notification is tapped while the app is backgrounded.
final navigatorKey = GlobalKey<NavigatorState>();

class TaskayaApp extends StatelessWidget {
  const TaskayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Taskaya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      home: const SplashScreen(),
    );
  }
}
