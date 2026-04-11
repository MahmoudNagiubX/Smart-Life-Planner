import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🧠',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Smart Life Planner',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your AI-powered personal operating system',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.signIn),
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.signUp),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}