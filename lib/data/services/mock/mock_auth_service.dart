import 'dart:async';

import '../../models/employee.dart';
import '../auth_service.dart';
import 'mock_data.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class MockAuthService implements AuthService {
  MockAuthService();

  final StreamController<Employee?> _controller =
      StreamController<Employee?>.broadcast();

  Employee? _currentUser;

  @override
  Stream<Employee?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<Employee?> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    final storedPassword = mockCredentials[normalizedEmail];

    if (storedPassword == null || storedPassword != password) {
      throw AuthException('Invalid email or password.');
    }

    final employee = findEmployeeByEmail(normalizedEmail);
    if (employee == null) {
      throw AuthException('Employee profile not found.');
    }

    _currentUser = employee;
    _controller.add(employee);
    return employee;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}



