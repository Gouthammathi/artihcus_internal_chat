import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/brand_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_record.dart';
import 'widgets/attendance_history_sheet.dart';

class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({super.key});

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isScanning = false;
  bool _isProcessingScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _isProcessingScan = false;
    });
    try {
      await _scannerController.start();
    } catch (_) {
      // ignore errors on restart
    }
  }

  Future<void> _stopScanning() async {
    try {
      await _scannerController.stop();
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }

    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _isProcessingScan = false;
    });
  }

  Future<void> _handleScan(String qrData) async {
    if (_isProcessingScan) return;
    setState(() => _isProcessingScan = true);

    final attendanceNotifier = ref.read(attendanceControllerProvider.notifier);
    final scanResult = attendanceNotifier.markAttendance(qrData);
    final message = scanResult.isUpdate
        ? 'Attendance updated for today at ${scanResult.record.formattedTime}.'
        : 'Attendance marked at ${scanResult.record.formattedTime}.';

    await _stopScanning();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: BrandColors.primary,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessingScan) return;

    final barcode = capture.barcodes.firstWhere(
      (code) => (code.rawValue ?? '').trim().isNotEmpty,
      orElse: () => const Barcode(rawValue: null),
    );
    final value = barcode.rawValue?.trim();

    if (value == null || value.isEmpty) {
      return;
    }

    _handleScan(value);
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

  Widget _buildScanPrompt(BuildContext context) {
    return Padding(
      key: const ValueKey('scan-prompt'),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 96,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tap to scan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Instantly capture your presence like you pay with UPI.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      key: const ValueKey('scan-active'),
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 2,
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surface.withOpacity(0.05),
                    colorScheme.surface.withOpacity(0.15),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton.filledTonal(
              tooltip: 'Close scanner',
              onPressed: _isProcessingScan ? null : _stopScanning,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Align the QR within the frame to mark attendance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _scannerController,
                        builder: (context, state, _) {
                          final torchState = state.torchState;
                          final hasTorch = torchState != TorchState.unavailable;
                          final isOn = torchState == TorchState.on;
                          return IconButton.filledTonal(
                            tooltip: hasTorch
                                ? (isOn ? 'Turn torch off' : 'Turn torch on')
                                : 'Torch unavailable',
                            onPressed: hasTorch
                                ? () => _scannerController.toggleTorch()
                                : null,
                            icon: Icon(
                              isOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton.filledTonal(
                        tooltip: 'Switch camera',
                        onPressed: () => _scannerController.switchCamera(),
                        icon: const Icon(Icons.cameraswitch_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                  'Mark your attendance in just one scan.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _isScanning ? null : () => _startScanning(),
                  child: Container(
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
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: _isScanning
                            ? _buildScannerView(context)
                            : _buildScanPrompt(context),
                      ),
                    ),
                  ),
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
