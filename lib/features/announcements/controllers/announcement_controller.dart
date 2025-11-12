import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/roles.dart';
import '../../../data/models/announcement.dart';
import '../../../data/services/announcement_service.dart';
import '../../../data/services/mock/mock_announcement_service.dart';
import '../../auth/controllers/auth_controller.dart';

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  final service = MockAnnouncementService();
  ref.onDispose(service.dispose);
  return service;
});

final announcementControllerProvider = StateNotifierProvider<
    AnnouncementController, AsyncValue<List<Announcement>>>((ref) {
  final service = ref.watch(announcementServiceProvider);
  final authState = ref.watch(authControllerProvider);
  return AnnouncementController(
    announcementService: service,
    currentEmployeeId: authState.valueOrNull?.id,
    currentRole: authState.valueOrNull?.role,
  );
});

class AnnouncementController extends StateNotifier<AsyncValue<List<Announcement>>> {
  AnnouncementController({
    required AnnouncementService announcementService,
    required this.currentEmployeeId,
    required this.currentRole,
  })  : _announcementService = announcementService,
        super(const AsyncValue.loading()) {
    _subscription = _announcementService.watchAnnouncements().listen(
      (announcements) => state = AsyncValue.data(announcements),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
  }

  final AnnouncementService _announcementService;
  final String? currentEmployeeId;
  final EmployeeRole? currentRole;
  late final StreamSubscription<List<Announcement>> _subscription;

  bool get canPublish =>
      currentRole?.canBroadcastAnnouncements ?? false;

  Future<void> publish(Announcement announcement) async {
    if (!canPublish) {
      throw StateError('Insufficient permissions to publish announcements.');
    }

    await _announcementService.publishAnnouncement(announcement);
  }

  Future<void> acknowledge(String announcementId) async {
    final employeeId = currentEmployeeId;
    if (employeeId == null) return;

    await _announcementService.acknowledgeAnnouncement(
      announcementId: announcementId,
      employeeId: employeeId,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}



