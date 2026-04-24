import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_life_planner/core/network/providers.dart';
import 'package:smart_life_planner/core/storage/token_storage.dart';
import 'package:smart_life_planner/main.dart';

class _TestTokenStorage extends TokenStorage {
  @override
  Future<bool> hasToken() async => false;

  @override
  Future<String?> getToken() async => null;
}

void main() {
  testWidgets('shows welcome screen for signed out users', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_TestTokenStorage()),
        ],
        child: const SmartLifePlannerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart Life Planner'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
