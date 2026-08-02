import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskaya/main.dart';

/// Pumps the app and rides past the splash screen's minimum display timer.
Future<void> pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const TaskayaBootstrap());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

Future<void> openLogin(WidgetTester tester) async {
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}

Future<void> loginAsDemo(WidgetTester tester) async {
  await openLogin(tester);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'), 'demo@taskaya.app');
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), 'demo123');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots through splash to the Welcome screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaskayaBootstrap());
    await tester.pump();

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('aya'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Get Started leads to Login, and Sign Up opens Signup',
      (WidgetTester tester) async {
    await pumpPastSplash(tester);
    await openLogin(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'Confirm password'), findsOneWidget);
  });

  testWidgets('Wrong credentials show an error on Login',
      (WidgetTester tester) async {
    await pumpPastSplash(tester);
    await openLogin(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'nobody@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'wrongpass');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password'), findsOneWidget);
  });

  testWidgets('Signup rejects mismatched passwords, then creates an account',
      (WidgetTester tester) async {
    await pumpPastSplash(tester);
    await openLogin(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'), 'different');
    await tester.tap(find.text('Sign Up').last);
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
    await tester.tap(find.text('Sign Up').last);
    await tester.pumpAndSettle();
    expect(find.text('Taskaya'), findsOneWidget);
  });

  testWidgets('Notification bell shows due reminders and marks them read',
      (WidgetTester tester) async {
    await pumpPastSplash(tester);
    await loginAsDemo(tester);

    // Seeded tasks: one due today, one due tomorrow -> 2 unread.
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_active_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Finish Phase 1 report'), findsWidgets);
    expect(find.text('Design login screen'), findsWidgets);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);

    // Close the sheet: badge is gone, bell is idle.
    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('Demo login lands on Home; logout returns to Login',
      (WidgetTester tester) async {
    await pumpPastSplash(tester);
    await loginAsDemo(tester);

    expect(find.text('Taskaya'), findsOneWidget);
    expect(find.byIcon(Icons.logout_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
