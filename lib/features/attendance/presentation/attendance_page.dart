import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/brand_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_record.dart';
import '../models/attendance_qr_data.dart';
import '../services/attendance_qr_service.dart';
import 'widgets/attendance_history_sheet.dart';

class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({super.key});

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  Timer? _refreshTimer;
  AttendanceQrData? _currentQrData;
  int _refreshCountdown = 30; // seconds until next refresh

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    // Refresh immediately
    _refreshQrCode();

    // Set up timer to refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _refreshCountdown--;
        if (_refreshCountdown <= 0) {
          _refreshQrCode();
          _refreshCountdown = 30; // Reset countdown
        }
      });
    });
  }

  void _refreshQrCode() {
    final authState = ref.read(authControllerProvider);
    final user = authState.maybeWhen(
      data: (employee) => employee,
      orElse: () => null,
    );

    if (user != null) {
      setState(() {
        _currentQrData = AttendanceQrService.generateQrData(user);
        _refreshCountdown = 30;
      });
    }
  }


  Future<void> _openHistory(
    BuildContext context,
    List<AttendanceRecord> records,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceHistorySheet(
        records: records,
        onClear: () =>
            ref.read(attendanceControllerProvider.notifier).clearHistory(),
      ),
    );
  }

  Widget _buildQrCodeView(BuildContext context, AttendanceQrData qrData) {
    return Container(
      key: ValueKey(qrData.checkInTime), // Key changes when QR refreshes
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code
          QrImageView(
            data: qrData.toJsonString(),
            version: QrVersions.auto,
            size: 280,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 24),
          // Employee Info
          Text(
            qrData.firstName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BrandColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${qrData.role.toUpperCase()}${qrData.department != null ? ' • ${qrData.department}' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 24),
          // Refresh Countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BrandColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: BrandColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Refreshes in $_refreshCountdown seconds',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Show this QR code to the scanner',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.maybeWhen(
      data: (employee) => employee,
      orElse: () => null,
    );

    final records = ref.watch(attendanceControllerProvider);
    final today = DateTime.now();
    final todayRecord =
        records.firstWhereOrNull((record) => record.isSameDay(today));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                Text(
                  'Welcome back${user != null ? ', ${user.firstName}' : ''} 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: BrandColors.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  user != null
                      ? 'Show your QR code to mark attendance'
                      : 'Please sign in to generate your QR code',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                if (user != null && _currentQrData != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF26A21),
                          Color(0xFFFFA726),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.primary.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildQrCodeView(context, _currentQrData!),
                    ),
                  )
                else if (user == null)
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please sign in',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 32),
                _TodayStatusCard(todayRecord: todayRecord),
                const SizedBox(height: 20),
                _RecentHistoryCard(
                  records: records,
                  onTapHistory: () => _openHistory(context, records),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.todayRecord});

  final AttendanceRecord? todayRecord;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrandColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: BrandColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayRecord == null
                        ? 'You haven’t marked attendance yet.'
                        : 'Attendance marked at ${todayRecord!.formattedTime}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentHistoryCard extends StatelessWidget {
  const _RecentHistoryCard({
    required this.records,
    required this.onTapHistory,
  });

  final List<AttendanceRecord> records;
  final VoidCallback onTapHistory;

  @override
  Widget build(BuildContext context) {
    final latestRecords = records.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'History',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: onTapHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (latestRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No previous attendance found. Start scanning to build your history.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              )
            else
              Column(
                children: [
                  for (final record in latestRecords)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: BrandColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: BrandColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.formattedDate,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Checked in at ${record.formattedTime}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
