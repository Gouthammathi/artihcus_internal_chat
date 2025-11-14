import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constants/roles.dart';
import '../../models/employee.dart';
import '../auth_service.dart';

class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _authStateController = StreamController<Employee?>.broadcast();

  SupabaseAuthService() {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final employee = await _fetchEmployeeProfile(session.user.id);
        _authStateController.add(employee);
      } else {
        _authStateController.add(null);
      }
    });

    // Check initial session
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final employee = await _fetchEmployeeProfile(session.user.id);
      _authStateController.add(employee);
    } else {
      _authStateController.add(null);
    }
  }

  Future<Employee?> _fetchEmployeeProfile(String userId) async {
    try {
      // First, try to fetch user data
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      // If user doesn't exist in users table, return null
      if (userResponse == null) {
        print('User not found in users table: $userId');
        return null;
      }

      // Try to fetch employee data separately (more reliable than join)
      Map<String, dynamic>? employeeData;
      try {
        final employeeResponse = await _supabase
            .from('employees')
            .select('role, department')
            .eq('id', userId)
            .maybeSingle();
        
        employeeData = employeeResponse;
      } catch (e) {
        // Employee record might not exist, that's okay
        print('Employee record not found for user: $userId');
      }

      // Extract role and department
      final role = employeeData != null && employeeData['role'] != null
          ? employeeRoleFromString(employeeData['role'] as String)
          : EmployeeRole.employee;
      final department = employeeData?['department'] as String?;

      return Employee(
        id: userResponse['id'] as String,
        firstName: userResponse['first_name'] as String? ?? 'Unknown',
        lastName: userResponse['last_name'] as String? ?? 'User',
        email: userResponse['email'] as String? ?? '',
        role: role,
        department: department,
        avatarUrl: userResponse['avatar_url'] as String?,
      );
    } catch (e) {
      print('Error fetching employee profile: $e');
      return null;
    }
  }

  @override
  Stream<Employee?> authStateChanges() {
    return _authStateController.stream;
  }

  @override
  Future<Employee?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty) {
        throw Exception('Email is required');
      }
      if (password.isEmpty) {
        throw Exception('Password is required');
      }

      // Trim and normalize email to avoid whitespace issues
      final trimmedEmail = email.trim().toLowerCase();
      
      final response = await _supabase.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;
        
        // Try to fetch profile
        var employee = await _fetchEmployeeProfile(userId);
        
        // If profile doesn't exist, try to create it from auth user metadata
        if (employee == null) {
          try {
            final userMetadata = response.user!.userMetadata ?? <String, dynamic>{};
            final firstName = userMetadata['first_name'] as String? ?? 
                             response.user!.email?.split('@').first ?? 'User';
            final lastName = userMetadata['last_name'] as String? ?? '';
            final roleStr = userMetadata['role'] as String? ?? 'employee';
            final department = userMetadata['department'] as String?;
            
            // Try to create the profile manually
            await _createUserProfileManually(
              userId: userId,
              email: response.user!.email ?? trimmedEmail,
              firstName: firstName,
              lastName: lastName.isNotEmpty ? lastName : 'User',
              role: employeeRoleFromString(roleStr),
              department: department,
            );
            
            // Try fetching again
            employee = await _fetchEmployeeProfile(userId);
          } catch (e) {
            print('Failed to create user profile during login: $e');
            // Still throw an error so user knows something is wrong
            throw Exception('User profile not found. Please contact support.');
          }
        }
        
        return employee;
      }

      return null;
    } catch (e) {
      // Handle Supabase auth-specific errors
      String errorMessage;
      final errorString = e.toString().toLowerCase();
      
      // Check if it's an AuthException (Supabase Flutter)
      if (e is AuthException) {
        final authError = e;
        switch (authError.statusCode) {
          case 'invalid_credentials':
          case '400':
            errorMessage = 'Invalid email or password. Please check your credentials and try again.';
            break;
          case 'email_not_confirmed':
            errorMessage = 'Please confirm your email address before signing in. Check your inbox for the confirmation link.';
            break;
          case 'too_many_requests':
            errorMessage = 'Too many login attempts. Please wait a few minutes and try again.';
            break;
          default:
            errorMessage = authError.message.isNotEmpty 
                ? authError.message 
                : 'Failed to sign in. Please check your credentials and try again.';
        }
      } 
      // Handle common error patterns
      else if (errorString.contains('invalid') || 
               errorString.contains('credentials') ||
               errorString.contains('invalid login') ||
               errorString.contains('wrong password') ||
               errorString.contains('user not found')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } 
      else if (errorString.contains('email not confirmed') || 
               errorString.contains('email_not_confirmed')) {
        errorMessage = 'Please confirm your email address before signing in. Check your inbox for the confirmation link.';
      }
      else if (errorString.contains('network') || 
               errorString.contains('connection') ||
               errorString.contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      }
      else if (errorString.contains('400') || errorString.contains('bad request')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      }
      else {
        // Extract meaningful error message
        if (e.toString().contains(':')) {
          final parts = e.toString().split(':');
          if (parts.length > 1) {
            errorMessage = parts.sublist(1).join(':').trim();
          } else {
            errorMessage = 'Failed to sign in. Please check your credentials and try again.';
          }
        } else {
          errorMessage = 'Failed to sign in. Please check your credentials and try again.';
        }
      }
      
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  Future<Employee?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    EmployeeRole role = EmployeeRole.employee,
  }) async {
    try {
      // Normalize email
      final trimmedEmail = email.trim().toLowerCase();
      
      // Create auth user with metadata
      // The trigger will create records in both users and employees tables
      final response = await _supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'role': role.name,  // This will trigger employee record creation
          'department': department?.trim(),
        },
      );

      if (response.user != null) {
        final userId = response.user!.id;
        
        // Wait a moment for the trigger to complete
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Try to fetch the profile - if trigger failed, manually create records
        Employee? employee;
        try {
          employee = await _fetchEmployeeProfile(userId);
        } catch (e) {
          // Trigger might have failed, try to manually create the records
          try {
            await _createUserProfileManually(
              userId: userId,
              email: trimmedEmail,
              firstName: firstName.trim(),
              lastName: lastName.trim(),
              role: role,
              department: department?.trim(),
            );
            // Try fetching again
            employee = await _fetchEmployeeProfile(userId);
          } catch (manualError) {
            // If manual creation also fails, log but don't throw yet
            // The auth user was created, so we should return something
            print('Warning: Failed to create user profile: $manualError');
          }
        }
        
        // If we still don't have an employee record, return a basic one
        if (employee == null) {
          employee = Employee(
            id: userId,
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: trimmedEmail,
            role: role,
            department: department?.trim(),
          );
        }
        
        // Check if user has a session (email confirmed or auto-confirm enabled)
        if (response.session != null) {
          return employee;
        } else {
          // Email confirmation required - user data is stored but user needs to confirm email
          return employee;
        }
      }

      return null;
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.statusCode) {
        case 'user_already_registered':
        case 'email_already_exists':
          errorMessage = 'An account with this email already exists. Please sign in instead.';
          break;
        case 'weak_password':
          errorMessage = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'invalid_email':
          errorMessage = 'Please enter a valid email address.';
          break;
        default:
          errorMessage = e.message.isNotEmpty 
              ? e.message 
              : 'Failed to create account. Please try again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('user already') || errorString.contains('already exists')) {
        throw Exception('An account with this email already exists. Please sign in instead.');
      } else if (errorString.contains('500') || errorString.contains('internal server')) {
        throw Exception('Server error during signup. The account may have been created. Please try signing in.');
      } else {
        throw Exception('Failed to sign up: ${e.toString()}');
      }
    }
  }

  /// Manually create user and employee records if the trigger fails
  Future<void> _createUserProfileManually({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required EmployeeRole role,
    String? department,
  }) async {
    try {
      // First check if user already exists
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (existingUser == null) {
        // Insert new user record
        await _supabase.from('users').insert({
          'id': userId,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        });
      } else {
        // Update existing user record
        await _supabase.from('users').update({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        }).eq('id', userId);
      }
      
      // Check if employee record exists
      final existingEmployee = await _supabase
          .from('employees')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (existingEmployee == null) {
        // Insert new employee record
        await _supabase.from('employees').insert({
          'id': userId,
          'role': role.name,
          'department': department,
        });
      } else {
        // Update existing employee record
        await _supabase.from('employees').update({
          'role': role.name,
          'department': department,
        }).eq('id', userId);
      }
    } catch (e) {
      // If this fails, it might be due to RLS or other constraints
      // Log the error with details
      print('Error creating user profile manually: $e');
      // Check if it's an RLS error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('row-level security') || 
          errorString.contains('42501') ||
          errorString.contains('forbidden') ||
          errorString.contains('403')) {
        throw Exception(
          'Permission denied. Please ensure the database RLS policies allow users to create their own profile. '
          'Run the migration_fix_rls_policies.sql script in Supabase SQL Editor.'
        );
      }
      rethrow;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

