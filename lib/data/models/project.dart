import 'package:equatable/equatable.dart';

enum ProjectStatus { onTrack, atRisk, blocked, completed }

class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.ownerId,
    required this.progress,
    this.dueDate,
    this.teamMembers = const [],
    this.milestones = const [],
  });

  final String id;
  final String name;
  final String description;
  final ProjectStatus status;
  final String ownerId;
  final double progress;
  final DateTime? dueDate;
  final List<String> teamMembers;
  final List<String> milestones;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    ProjectStatus? status,
    String? ownerId,
    double? progress,
    DateTime? dueDate,
    List<String>? teamMembers,
    List<String>? milestones,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
      teamMembers: teamMembers ?? this.teamMembers,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'status': status.name,
        'ownerId': ownerId,
        'progress': progress,
        'dueDate': dueDate?.toIso8601String(),
        'teamMembers': teamMembers,
        'milestones': milestones,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        status: ProjectStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ProjectStatus.onTrack,
        ),
        ownerId: json['ownerId'] as String,
        progress: (json['progress'] as num).toDouble(),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        teamMembers: (json['teamMembers'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        milestones: (json['milestones'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        status,
        ownerId,
        progress,
        dueDate,
        teamMembers,
        milestones,
      ];
}



