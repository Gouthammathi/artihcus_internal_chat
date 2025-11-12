enum EmployeeRole {
  employee,
  lead,
  manager,
  admin;

  String get displayName {
    return switch (this) {
      EmployeeRole.employee => 'Employee',
      EmployeeRole.lead => 'Team Lead',
      EmployeeRole.manager => 'Manager',
      EmployeeRole.admin => 'Administrator',
    };
  }

  bool get canBroadcastAnnouncements =>
      this == EmployeeRole.lead || this == EmployeeRole.manager || this == EmployeeRole.admin;

  bool get canManageProjects =>
      this == EmployeeRole.manager || this == EmployeeRole.admin;

  bool get canManageSupportTickets =>
      this == EmployeeRole.lead || this == EmployeeRole.manager || this == EmployeeRole.admin;

  bool get isAdmin => this == EmployeeRole.admin;
}

EmployeeRole employeeRoleFromString(String value) {
  return EmployeeRole.values.firstWhere(
    (role) => role.name == value.toLowerCase(),
    orElse: () => EmployeeRole.employee,
  );
}



