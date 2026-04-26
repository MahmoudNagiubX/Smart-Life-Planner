import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/core/theme/app_theme.dart';
import 'package:smart_life_planner/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding first step lays out and advances', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 10'), findsOneWidget);
    expect(find.text('Preferred Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 10'), findsOneWidget);
    expect(find.text('Country or City'), findsOneWidget);
  });
}
