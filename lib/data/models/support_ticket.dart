import 'package:equatable/equatable.dart';

enum SupportTicketStatus { open, inProgress, resolved, closed }

enum SupportTicketPriority { low, normal, high, urgent }

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.tags = const [],
  });

  final String id;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;
  final List<String> tags;

  SupportTicket copyWith({
    String? id,
    String? subject,
    String? description,
    SupportTicketStatus? status,
    SupportTicketPriority? priority,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    List<String>? tags,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'subject': subject,
        'description': description,
        'status': status.name,
        'priority': priority.name,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'assignedTo': assignedTo,
        'tags': tags,
      };

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        subject: json['subject'] as String,
        description: json['description'] as String,
        status: SupportTicketStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => SupportTicketStatus.open,
        ),
        priority: SupportTicketPriority.values.firstWhere(
          (value) => value.name == json['priority'],
          orElse: () => SupportTicketPriority.normal,
        ),
        createdBy: json['createdBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt:
            json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        assignedTo: json['assignedTo'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );

  @override
  List<Object?> get props => [
        id,
        subject,
        description,
        status,
        priority,
        createdBy,
        createdAt,
        updatedAt,
        assignedTo,
        tags,
      ];
}



