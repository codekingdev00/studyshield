import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyfocus/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen lists the fallback study group and materials',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StudyShieldApp());
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('StudyShield'), findsOneWidget);
    expect(find.text('Grade 10 Study Group'), findsOneWidget);
    expect(find.text('Parts of Speech'), findsOneWidget);
    expect(find.text('Quadratic Equations'), findsOneWidget);
    expect(find.text('Newton\'s Laws of Motion'), findsOneWidget);
  });

  testWidgets('Opening a material shows its content and a Start button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StudyShieldApp());
    await tester.pumpAndSettle(const Duration(seconds: 10));

    await tester.tap(find.text('Parts of Speech'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Start Reading'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.textContaining('parts of speech'), findsWidgets);
    expect(find.text('Watch Video'), findsOneWidget);
  });
}
