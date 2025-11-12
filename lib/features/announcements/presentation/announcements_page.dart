import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/brand_colors.dart';
import '../../../core/constants/roles.dart';
import '../../../data/models/announcement.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsState = ref.watch(announcementControllerProvider);
    final currentEmployee = ref.watch(authControllerProvider).valueOrNull;
    final controller = ref.watch(announcementControllerProvider.notifier);

    return Scaffold(
      floatingActionButton: controller.canPublish
          ? FloatingActionButton.extended(
              onPressed: () => _showComposeSheet(context, ref),
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('New announcement'),
            )
          : null,
      body: announcementsState.when(
        data: (announcements) => RefreshIndicator(
          onRefresh: () async {
            // No-op for mock service; placeholder for future API refresh.
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final acknowledged = currentEmployee == null
                  ? false
                  : announcement.acknowledgedBy.contains(currentEmployee.id);
              return _AnnouncementCard(
                announcement: announcement,
                acknowledged: acknowledged,
                onAcknowledge: acknowledged
                    ? null
                    : () => ref
                        .read(announcementControllerProvider.notifier)
                        .acknowledge(announcement.id),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load announcements\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _showComposeSheet(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    AnnouncementPriority priority = AnnouncementPriority.normal;
    final selectedRoles = ValueNotifier<Set<EmployeeRole>>(EmployeeRole.values.toSet());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Publish announcement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Priority'),
                      const SizedBox(width: 16),
                      DropdownButton<AnnouncementPriority>(
                        value: priority,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => priority = value);
                        },
                        items: AnnouncementPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Send to roles',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<Set<EmployeeRole>>(
                    valueListenable: selectedRoles,
                    builder: (context, roles, _) {
                      return Wrap(
                        spacing: 8,
                        children: EmployeeRole.values
                            .map(
                              (role) => FilterChip(
                                selected: roles.contains(role),
                                onSelected: (value) {
                                  final updated = Set<EmployeeRole>.from(roles);
                                  if (value) {
                                    updated.add(role);
                                  } else {
                                    updated.remove(role);
                                  }
                                  selectedRoles.value = updated;
                                },
                                label: Text(role.displayName),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.campaign_outlined),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          bodyController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Title and message are required.'),
                          ),
                        );
                        return;
                      }

                      if (selectedRoles.value.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select at least one role.'),
                          ),
                        );
                        return;
                      }

                      final controller =
                          ref.read(announcementControllerProvider.notifier);
                      await controller.publish(
                        Announcement(
                          id: '',
                          title: titleController.text.trim(),
                          body: bodyController.text.trim(),
                          priority: priority,
                          publishedAt: DateTime.now(),
                          publishedBy:
                              ref.read(authControllerProvider).valueOrNull?.id ?? '',
                          targetRoles: selectedRoles.value.toList(),
                        ),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    label: const Text('Publish'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.acknowledged,
    required this.onAcknowledge,
  });

  final Announcement announcement;
  final bool acknowledged;
  final VoidCallback? onAcknowledge;

  Color _priorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return Colors.blueGrey;
      case AnnouncementPriority.normal:
        return BrandColors.primary;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.critical:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • hh:mm a');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _priorityColor(announcement.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  announcement.priority.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _priorityColor(announcement.priority),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(announcement.publishedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: announcement.targetRoles
                  .map((role) => Chip(
                        label: Text(role.displayName),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${announcement.acknowledgedBy.length} acknowledgements',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.black54),
                ),
                FilledButton.tonalIcon(
                  icon: Icon(acknowledged
                      ? Icons.check_circle
                      : Icons.check_circle_outline),
                  onPressed: onAcknowledge,
                  label: Text(acknowledged ? 'Acknowledged' : 'Acknowledge'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

