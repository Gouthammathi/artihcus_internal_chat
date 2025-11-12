import 'package:equatable/equatable.dart';

import '../../core/constants/roles.dart';

class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.department,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final EmployeeRole role;
  final String? department;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName';

  String get initials {
    final buffer = StringBuffer();
    if (firstName.isNotEmpty) {
      buffer.write(firstName.substring(0, 1));
    }
    if (lastName.isNotEmpty) {
      buffer.write(lastName.substring(0, 1));
    }
    return buffer.toString().toUpperCase();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role.name,
        'department': department,
        'avatarUrl': avatarUrl,
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        role: employeeRoleFromString(json['role'] as String),
        department: json['department'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    EmployeeRole? role,
    String? department,
    String? avatarUrl,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        role,
        department,
        avatarUrl,
      ];
}

