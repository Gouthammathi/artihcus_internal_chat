import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/brand_colors.dart';
import '../../../data/models/employee.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/models/attendance_record.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../packaging/presentation/orders_list_page.dart';
import '../../packaging/presentation/create_order_page.dart';

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
      child: Container(
        color: const Color(0xFFF6F7FB),
        child: Column(
          children: [
            // Top Header Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandColors.primary.withOpacity(0.12),
                    BrandColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hey${userFirstName != null ? ' $userFirstName' : ''},',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Packaging & attendance at a glance',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PillButton(
                              label: 'Mark Attendance',
                              icon: Icons.touch_app_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: features[0].builder),
                              ),
                            ),
                            _PillButton(
                              label: 'View Orders',
                              icon: Icons.inventory_2_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrdersListPage(),
                                ),
                              ),
                            ),
                            _PillButton(
                              label: 'Create Order',
                              icon: Icons.add_shopping_cart,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateOrderPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: BrandColors.primary.withOpacity(0.1),
                      child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  color: BrandColors.primary,
                                  size: 26,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: BrandColors.primary,
                              size: 26,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Time and Summary Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('hh:mm a').format(today),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMM d, yyyy • EEEE').format(today),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoBadge(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Check In',
                            value: checkInTime,
                          ),
                          const SizedBox(height: 10),
                          _InfoBadge(
                            icon: Icons.arrow_downward_rounded,
                            label: 'Check Out',
                            value: checkOutTime,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions for packaging and attendance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Mark Attendance',
                          description: 'Tap to check-in/out instantly',
                          icon: Icons.fingerprint_rounded,
                          color: BrandColors.primary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: features[0].builder),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Packaging',
                          description: 'Track and update orders',
                          icon: Icons.inventory_2_outlined,
                          color: Colors.deepOrange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrdersListPage(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Create Order',
                          description: 'Start a new packing job',
                          icon: Icons.add_shopping_cart,
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateOrderPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Total Hours',
                          description: totalHours,
                          icon: Icons.access_time_filled,
                          color: Colors.indigo,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Packaging focus cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packaging Hub',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              color: Colors.deepOrange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Stay on top of order flow',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ChipButton(
                              label: 'View Orders',
                              icon: Icons.list_alt_outlined,
                              color: Colors.deepOrange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrdersListPage(),
                                ),
                              ),
                            ),
                            _ChipButton(
                              label: 'Create Order',
                              icon: Icons.add,
                              color: Colors.green,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateOrderPage(),
                                ),
                              ),
                            ),
                            _ChipButton(
                              label: 'Attendance',
                              icon: Icons.fingerprint,
                              color: BrandColors.primary,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: features[0].builder),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: BrandColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: BrandColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: BrandColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ],
    );
  }
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
