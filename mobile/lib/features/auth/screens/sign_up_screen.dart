import 'package:flutter/material.dart';
import 'package:smart_life_planner/core/l10n/app_localizations.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(child: Text('${l10n.signUp} - ${l10n.comingSoon}')),
    );
  }
}
