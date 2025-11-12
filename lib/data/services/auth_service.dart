import '../../data/models/employee.dart';

abstract class AuthService {
  Stream<Employee?> authStateChanges();

  Future<Employee?> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}



