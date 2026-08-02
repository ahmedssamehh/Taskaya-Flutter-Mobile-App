import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/task_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const TaskayaBootstrap());
}

class TaskayaBootstrap extends StatelessWidget {
  const TaskayaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => MockAuthRepository()),
        Provider<TaskRepository>(create: (_) => TaskRepository()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(context.read<TaskRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: const TaskayaApp(),
    );
  }
}
