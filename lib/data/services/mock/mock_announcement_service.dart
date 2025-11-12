import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../models/announcement.dart';
import '../announcement_service.dart';
import 'mock_data.dart';

class MockAnnouncementService implements AnnouncementService {
  MockAnnouncementService()
      : _controller = StreamController<List<Announcement>>.broadcast() {
    _controller.add(List<Announcement>.from(mockAnnouncements));
  }

  final Uuid _uuid = const Uuid();
  final StreamController<List<Announcement>> _controller;
  final List<Announcement> _buffer = List<Announcement>.from(mockAnnouncements);

  @override
  Stream<List<Announcement>> watchAnnouncements() => _controller.stream;

  @override
  Future<void> publishAnnouncement(Announcement announcement) async {
    final item = announcement.id.isEmpty
        ? announcement.copyWith(id: _uuid.v4(), publishedAt: DateTime.now())
        : announcement;
    _buffer.insert(0, item);
    _controller.add(List<Announcement>.from(_buffer));
  }

  @override
  Future<void> acknowledgeAnnouncement({
    required String announcementId,
    required String employeeId,
  }) async {
    final index = _buffer.indexWhere((element) => element.id == announcementId);
    if (index == -1) return;

    final announcement = _buffer[index];
    if (announcement.acknowledgedBy.contains(employeeId)) return;

    final updated = announcement.copyWith(
      acknowledgedBy: [...announcement.acknowledgedBy, employeeId],
    );
    _buffer[index] = updated;
    _controller.add(List<Announcement>.from(_buffer));
  }

  void dispose() {
    _controller.close();
  }
}



