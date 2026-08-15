import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/routing/page_transitions.dart';
import 'data/models/task.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firestore_task_repository.dart';
import 'data/repositories/task_repository.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/add_edit/add_edit_task_screen.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '389218008252-icqtau8k0o8joh8r36t9dtau58i7k7k0.apps.googleusercontent.com',
  );
  await LocalNotificationService.instance.init();
  LocalNotificationService.instance.onNotificationTap = _openTaskFromNotification;
  runApp(const TaskayaBootstrap());
}

/// Opens the tapped task's edit screen by looking it up in whichever
/// [TaskProvider] is currently mounted for the signed-in user.
void _openTaskFromNotification(String taskId) {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  final tasks = context.read<TaskProvider>();
  final task = [...tasks.pending, ...tasks.completed]
      .where((t) => t.id == taskId)
      .cast<Task?>()
      .firstOrNull;
  if (task == null) return;
  navigatorKey.currentState?.push(slideUpRoute(AddEditTaskScreen(task: task)));
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Placeholder repository used while signed out, so the app never issues a
/// Firestore query without an authenticated owner.
class _SignedOutTaskRepository implements TaskRepository {
  @override
  String newId() => '';

  @override
  Stream<List<Task>> watchAll() => Stream.value(const []);

  @override
  Future<void> upsert(Task task) async {}

  @override
  Future<void> delete(String id) async {}
}

class TaskayaBootstrap extends StatelessWidget {
  const TaskayaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            notificationService: LocalNotificationService.instance,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) =>
              TaskProvider(_SignedOutTaskRepository(), uid: null),
          update: (context, auth, previous) {
            final uid = auth.currentUser?.id;
            if (previous != null && previous.uid == uid) return previous;
            previous?.dispose();
            return TaskProvider(
              uid == null
                  ? _SignedOutTaskRepository()
                  : FirestoreTaskRepository(uid: uid),
              uid: uid,
              notificationService: LocalNotificationService.instance,
            );
          },
        ),
        ChangeNotifierProxyProvider<TaskProvider, NotificationProvider>(
          create: (_) => NotificationProvider()..load(),
          update: (_, tasks, notifications) =>
              notifications!..updateTasks(tasks.pending),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: const TaskayaApp(),
    );
  }
}
