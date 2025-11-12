import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/brand_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../profile/presentation/profile_page.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/leave_apply_tab.dart';
import 'tabs/teams_tab.dart';

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
      description: 'Scan to mark presence',
      icon: Icons.qr_code_scanner_rounded,
      builder: (_) => const HomeFeaturePage(
        title: 'Attendance',
        child: AttendanceTab(),
      ),
    ),
    _FeatureDefinition(
      label: 'Announcements',
      description: 'Latest company updates',
      icon: Icons.campaign_outlined,
      builder: (_) => const HomeFeaturePage(
        title: 'Announcements',
        child: AnnouncementsTab(),
      ),
    ),
    _FeatureDefinition(
      label: 'Teams',
      description: 'People & roles',
      icon: Icons.groups_rounded,
      builder: (_) => const HomeFeaturePage(
        title: 'Teams',
        child: TeamsTab(),
      ),
    ),
    _FeatureDefinition(
      label: 'Leave Apply',
      description: 'Request time off',
      icon: Icons.beach_access_rounded,
      builder: (_) => const HomeFeaturePage(
        title: 'Leave Apply',
        child: LeaveApplyTab(),
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

class _HomeGrid extends StatelessWidget {
  const _HomeGrid({
    required this.features,
    required this.userFirstName,
  });

  final List<_FeatureDefinition> features;
  final String? userFirstName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final crossAxisCount = isWide ? 4 : 2;
        final childAspectRatio = 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome${userFirstName != null ? ', $userFirstName' : ''} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BrandColors.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a workspace feature to continue.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _FeatureCard(definition: feature);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.definition});

  final _FeatureDefinition definition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: definition.builder),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: BrandColors.subtleBorder),
          boxShadow: [
            BoxShadow(
              color: BrandColors.primary.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              definition.icon,
              size: 32,
              color: BrandColors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              definition.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              definition.description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
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
  const _FeatureDefinition({
    required this.label,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String label;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}
