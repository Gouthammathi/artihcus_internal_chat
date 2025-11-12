import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_record.dart';

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, List<AttendanceRecord>>(
  (ref) => AttendanceController(),
);

class AttendanceController extends StateNotifier<List<AttendanceRecord>> {
  AttendanceController() : super(const []);

  ({AttendanceRecord record, bool isUpdate}) markAttendance(String qrData) {
    final now = DateTime.now();
    final normalizedCode = qrData.trim();
    final hasExistingForToday = state.any((record) => record.isSameDay(now));

    final newRecord = AttendanceRecord(
      id: const Uuid().v4(),
      qrData: normalizedCode.isEmpty ? 'unknown-location' : normalizedCode,
      timestamp: now,
    );

    final existing = state.where((record) => !record.isSameDay(now)).toList();

    state = [newRecord, ...existing];
    return (record: newRecord, isUpdate: hasExistingForToday);
  }

  void clearHistory() => state = const [];
}
