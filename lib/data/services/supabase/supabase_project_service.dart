import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../../models/project.dart';
import '../project_service.dart';

class SupabaseProjectService implements ProjectService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _projectsController = StreamController<List<Project>>.broadcast();
  final _uuid = const Uuid();
  RealtimeChannel? _realtimeChannel;

  SupabaseProjectService() {
    _subscribeToProjects();
  }

  void _subscribeToProjects() {
    _realtimeChannel = _supabase
        .channel('projects_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'projects',
          callback: (payload) {
            _refreshProjects();
          },
        )
        .subscribe();
  }

  Future<void> _refreshProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('''
            *,
            members:project_members(employee_id)
          ''')
          .order('created_at', ascending: false);

      final projects = (response as List).map((json) {
        final members = (json['members'] as List?)
                ?.map((m) => (m as Map<String, dynamic>)['employee_id'] as String)
                .toList() ??
            [];

        return Project(
          id: json['id'] as String,
          name: json['name'] as String,
          description: json['description'] as String,
          status: ProjectStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => ProjectStatus.onTrack,
          ),
          ownerId: json['owner_id'] as String,
          progress: (json['progress'] as num).toDouble() / 100.0,
          dueDate: json['due_date'] != null
              ? DateTime.parse(json['due_date'] as String)
              : null,
          teamMembers: members,
          milestones: (json['milestones'] as List?)?.cast<String>() ?? [],
        );
      }).toList();

      _projectsController.add(projects);
    } catch (e) {
      _projectsController.addError(e);
    }
  }

  @override
  Stream<List<Project>> watchProjects() {
    // Initial load
    _refreshProjects();
    return _projectsController.stream;
  }

  @override
  Future<void> createProject(Project project) async {
    try {
      // Insert project
      await _supabase.from('projects').insert({
        'id': project.id,
        'name': project.name,
        'description': project.description,
        'status': project.status.name,
        'owner_id': project.ownerId,
        'progress': (project.progress * 100).toInt(),
        'due_date': project.dueDate?.toIso8601String(),
        'milestones': project.milestones,
      });

      // Insert team members
      if (project.teamMembers.isNotEmpty) {
        await _supabase.from('project_members').insert(
              project.teamMembers
                  .map((memberId) => {
                        'id': _uuid.v4(),
                        'project_id': project.id,
                        'employee_id': memberId,
                      })
                  .toList(),
            );
      }
    } catch (e) {
      throw Exception('Failed to create project: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProject(Project project) async {
    try {
      await _supabase.from('projects').update({
        'name': project.name,
        'description': project.description,
        'status': project.status.name,
        'progress': (project.progress * 100).toInt(),
        'due_date': project.dueDate?.toIso8601String(),
        'milestones': project.milestones,
      }).eq('id', project.id);

      // Update team members - delete old ones and insert new ones
      await _supabase.from('project_members').delete().eq('project_id', project.id);

      if (project.teamMembers.isNotEmpty) {
        await _supabase.from('project_members').insert(
              project.teamMembers
                  .map((memberId) => {
                        'id': _uuid.v4(),
                        'project_id': project.id,
                        'employee_id': memberId,
                      })
                  .toList(),
            );
      }
    } catch (e) {
      throw Exception('Failed to update project: ${e.toString()}');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _projectsController.close();
  }
}

