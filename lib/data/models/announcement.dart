import 'package:equatable/equatable.dart';

import '../../core/constants/roles.dart';

enum AnnouncementPriority { low, normal, high, critical }

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.publishedAt,
    required this.publishedBy,
    this.targetRoles = const [],
    this.acknowledgedBy = const [],
  });

  final String id;
  final String title;
  final String body;
  final AnnouncementPriority priority;
  final DateTime publishedAt;
  final String publishedBy;
  final List<EmployeeRole> targetRoles;
  final List<String> acknowledgedBy;

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    AnnouncementPriority? priority,
    DateTime? publishedAt,
    String? publishedBy,
    List<EmployeeRole>? targetRoles,
    List<String>? acknowledgedBy,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      targetRoles: targetRoles ?? this.targetRoles,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'priority': priority.name,
        'publishedAt': publishedAt.toIso8601String(),
        'publishedBy': publishedBy,
        'targetRoles': targetRoles.map((e) => e.name).toList(),
        'acknowledgedBy': acknowledgedBy,
      };

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        priority: AnnouncementPriority.values.firstWhere(
          (value) => value.name == json['priority'],
          orElse: () => AnnouncementPriority.normal,
        ),
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        publishedBy: json['publishedBy'] as String,
        targetRoles: (json['targetRoles'] as List<dynamic>? ?? [])
            .map((e) => employeeRoleFromString(e as String))
            .toList(),
        acknowledgedBy: (json['acknowledgedBy'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        priority,
        publishedAt,
        publishedBy,
        targetRoles,
        acknowledgedBy,
      ];
}



