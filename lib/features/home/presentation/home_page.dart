import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/brand_colors.dart';
import '../../../data/models/employee.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/models/attendance_record.dart';
import '../../profile/presentation/profile_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedNavIndex = 0;

  late final List<_FeatureDefinition> _features = [
    _FeatureDefinition(
      label: 'Attendance',
      builder: (_) => HomeFeaturePage(
        title: 'Attendance',
        child: AttendanceTab(),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.maybeWhen(
      data: (employee) => employee,
      orElse: () => null,
    );

    return Scaffold(
      body: SafeArea(
        child: _selectedNavIndex == 0
            ? _HomeGrid(
                features: _features,
                userFirstName: user?.firstName,
                user: user,
              )
            : const ProfilePage(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedNavIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeGrid extends ConsumerWidget {
  const _HomeGrid({
    required this.features,
    required this.userFirstName,
    required this.user,
  });

  final List<_FeatureDefinition> features;
  final String? userFirstName;
  final Employee? user;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceRecords = ref.watch(attendanceControllerProvider);
    final today = DateTime.now();
    AttendanceRecord? todayRecord;
    try {
      todayRecord = attendanceRecords.firstWhere(
        (record) => record.isSameDay(today),
      );
    } catch (e) {
      todayRecord = null;
    }
    
    // Get check-in and check-out times for today
    String checkInTime = '--:--';
    String checkOutTime = '--:--';
    String totalHours = '--:--';
    
    if (todayRecord != null) {
      checkInTime = DateFormat('hh:mm a').format(todayRecord.timestamp);
      // For now, check-out would be from a different record, but we'll show check-in time
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey${userFirstName != null ? ' $userFirstName' : ''}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getGreeting()} Mark your attendance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: BrandColors.primary.withOpacity(0.1),
                  child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user!.avatarUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: BrandColors.primary,
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: BrandColors.primary,
                          size: 24,
                        ),
                ),
              ],
            ),
          ),

          // Time and Date Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Text(
                  DateFormat('hh:mm a').format(today),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontSize: 48,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM d, yyyy - EEEE').format(today),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Large Check In Button
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: features[0].builder),
            ),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 3,
                ),
                color: Colors.white,
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.primary.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 48,
                      color: BrandColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Check In',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: BrandColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Bottom Stats Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _BottomStatItem(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Check In',
                    value: checkInTime,
                  ),
                ),
                Expanded(
                  child: _BottomStatItem(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Check Out',
                    value: checkOutTime,
                  ),
                ),
                Expanded(
                  child: _BottomStatItem(
                    icon: Icons.access_time_rounded,
                    label: 'Total Hrs',
                    value: totalHours,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BottomStatItem extends StatelessWidget {
  const _BottomStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: BrandColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: CustomPaint(
            painter: DashedLinePainter(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class HomeFeaturePage extends StatelessWidget {
  const HomeFeaturePage({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SafeArea(child: child),
    );
  }
}

class _FeatureDefinition {
  _FeatureDefinition({
    required this.label,
    required this.builder,
  });

  final String label;
  final WidgetBuilder builder;
}
