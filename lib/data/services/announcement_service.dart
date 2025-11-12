import '../models/announcement.dart';

abstract class AnnouncementService {
  Stream<List<Announcement>> watchAnnouncements();

  Future<void> publishAnnouncement(Announcement announcement);

  Future<void> acknowledgeAnnouncement({
    required String announcementId,
    required String employeeId,
  });
}



