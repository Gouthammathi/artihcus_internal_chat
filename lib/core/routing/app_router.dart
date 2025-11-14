import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/home/presentation/home_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final isAuthenticated = authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';

      if (!isAuthenticated) {
        // Allow access to login and signup pages
        if (loggingIn || signingUp) {
          return null;
        }
        return '/login';
      }

      // If authenticated and trying to access login/signup, redirect to home
      if (loggingIn || signingUp) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SignupPage()),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomePage()),
      ),
      GoRoute(
        path: '/auth/callback',
        name: 'auth-callback',
        redirect: (context, state) {
          // Handle email confirmation callback
          return '/';
        },
      ),
    ],
  );
});
