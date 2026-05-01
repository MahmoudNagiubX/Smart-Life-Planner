import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../focus/providers/focus_provider.dart';
import '../widgets/floating_nav_bar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home/tasks'))   return 1;
    if (location.startsWith('/home/focus'))   return 2;
    if (location.startsWith('/home/prayer'))  return 3;
    if (location.startsWith('/home/profile')) return 4;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home');         break;
      case 1: context.go('/home/tasks');   break;
      case 2: context.go('/home/focus');   break;
      case 3: context.go('/home/prayer');  break;
      case 4: context.go('/home/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location   = GoRouterState.of(context).uri.toString();
    final focusState = ref.watch(focusProvider);

    final hideNav =
        location.startsWith('/home/focus') &&
        focusState.activeSession != null &&
        focusState.distractionFreeMode;

    return Scaffold(
      body: child,
      bottomNavigationBar: hideNav
          ? null
          : FloatingNavBar(
              currentIndex: _currentIndex(context),
              onTap: (i) => _onTabTap(context, i),
            ),
    );
  }
}
