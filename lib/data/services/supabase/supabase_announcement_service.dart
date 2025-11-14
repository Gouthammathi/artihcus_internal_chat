import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constants/roles.dart';
import '../../models/announcement.dart';
import '../announcement_service.dart';

class SupabaseAnnouncementService implements AnnouncementService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _announcementsController = StreamController<List<Announcement>>.broadcast();
  final _uuid = const Uuid();
  RealtimeChannel? _realtimeChannel;

  SupabaseAnnouncementService() {
    _subscribeToAnnouncements();
  }

  void _subscribeToAnnouncements() {
    _realtimeChannel = _supabase
        .channel('announcements_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            _refreshAnnouncements();
          },
        )
        .subscribe();
  }

  Future<void> _refreshAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select('''
            *,
            acknowledgements:announcement_acknowledgements(user_id)
          ''')
          .order('created_at', ascending: false);

      final announcements = (response as List).map((json) {
        final acknowledgements = (json['acknowledgements'] as List?)
                ?.map((a) => (a as Map<String, dynamic>)['user_id'] as String)
                .toList() ??
            [];

        final targetRoles = (json['target_roles'] as List?)
                ?.map((role) => employeeRoleFromString(role as String))
                .toList() ??
            [];

        return Announcement(
          id: json['id'] as String,
          title: json['title'] as String,
          body: json['body'] as String,
          priority: AnnouncementPriority.values.firstWhere(
            (p) => p.name == json['priority'],
            orElse: () => AnnouncementPriority.normal,
          ),
          publishedAt: DateTime.parse(json['created_at'] as String),
          publishedBy: json['published_by'] as String,
          targetRoles: targetRoles,
          acknowledgedBy: acknowledgements,
        );
      }).toList();

      _announcementsController.add(announcements);
    } catch (e) {
      _announcementsController.addError(e);
    }
  }

  @override
  Stream<List<Announcement>> watchAnnouncements() {
    // Initial load
    _refreshAnnouncements();
    return _announcementsController.stream;
  }

  @override
  Future<void> publishAnnouncement(Announcement announcement) async {
    try {
      await _supabase.from('announcements').insert({
        'id': announcement.id,
        'title': announcement.title,
        'body': announcement.body,
        'priority': announcement.priority.name,
        'published_by': announcement.publishedBy,
        'target_roles': announcement.targetRoles.map((r) => r.name).toList(),
      });
    } catch (e) {
      throw Exception('Failed to publish announcement: ${e.toString()}');
    }
  }

  @override
  Future<void> acknowledgeAnnouncement({
    required String announcementId,
    required String employeeId,
  }) async {
    try {
      await _supabase.from('announcement_acknowledgements').upsert({
        'id': _uuid.v4(),
        'announcement_id': announcementId,
        'user_id': employeeId,
      }, onConflict: 'announcement_id,user_id');
    } catch (e) {
      throw Exception('Failed to acknowledge announcement: ${e.toString()}');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _announcementsController.close();
  }
}

