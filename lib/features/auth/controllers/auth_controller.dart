import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/employee.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/mock/mock_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = MockAuthService();
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
      final employee = await _authService.signIn(email: email, password: password);
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



