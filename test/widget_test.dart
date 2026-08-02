import 'package:flutter_test/flutter_test.dart';

import 'package:taskaya/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskayaBootstrap());
    await tester.pump();

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('aya'), findsOneWidget);
  });
}
