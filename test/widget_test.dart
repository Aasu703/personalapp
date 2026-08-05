import 'package:flutter_test/flutter_test.dart';

import 'package:meroapp/app/app.dart';

void main() {
  testWidgets('app starts on splash and flows to onboarding', (tester) async {
    await tester.pumpWidget(const MeroApp());

    expect(find.text('MeroApp'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Secure Authentication'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('skipping onboarding opens the login screen', (tester) async {
    await tester.pumpWidget(const MeroApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('login form validates empty fields', (tester) async {
    await tester.pumpWidget(const MeroApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
