import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/registration_page.dart';
import '../../presentation/pages/email_verification_page.dart';
import '../../presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Initialize auth on app start
      Future.microtask(() => authNotifier.initializeAuth());
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});

/// Legacy function for backward compatibility
GoRouter getAppRouter(WidgetRef ref) {
  return ref.watch(appRouterProvider);
}

// Deprecated: Use appRouterProvider instead
late final GoRouter appRouter;
