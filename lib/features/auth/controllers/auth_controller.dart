import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/roles.dart';
import '../../../data/models/employee.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/supabase/supabase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = SupabaseAuthService();
  ref.onDispose(service.dispose);
  return service;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<Employee?>>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthController(authService: service);
});

class AuthController extends StateNotifier<AsyncValue<Employee?>> {
  AuthController({required AuthService authService})
      : _authService = authService,
        super(const AsyncValue.loading()) {
    _subscription = _authService.authStateChanges().listen(
      (employee) => state = AsyncValue.data(employee),
      onError: (error, stackTrace) => state = AsyncValue.error(error, stackTrace),
    );
  }

  final AuthService _authService;
  late final StreamSubscription<Employee?> _subscription;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('AuthController: Attempting sign in for $email');
      final employee = await _authService.signIn(email: email, password: password);
      print('AuthController: Sign in successful, employee: ${employee?.email}');
      state = AsyncValue.data(employee);
    } catch (error, stackTrace) {
      print('AuthController: Sign in error: $error');
      print('AuthController: Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    EmployeeRole role = EmployeeRole.employee,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = _authService as SupabaseAuthService;
      final employee = await service.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        department: department,
        role: role,
      );
      state = AsyncValue.data(employee);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}



