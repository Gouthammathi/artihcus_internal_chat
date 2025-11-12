import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/brand_colors.dart';
import '../../../../data/models/announcement.dart';
import '../../../../data/services/mock/mock_data.dart';

class AnnouncementsTab extends ConsumerWidget {
  const AnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = mockAnnouncements;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Announcements',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BrandColors.primary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stay updated with company news and highlights.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ...announcements.map(
            (announcement) {
              final priorityLabel = _priorityLabel(announcement.priority);
              final priorityColor = _priorityColor(announcement.priority);
              final publishedLabel = DateFormat('MMM d, yyyy • hh:mm a')
                  .format(announcement.publishedAt);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              priorityLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            publishedLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        announcement.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.body,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (announcements.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 48),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BrandColors.neutralBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BrandColors.subtleBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: BrandColors.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New updates will appear here as soon as they are published.',
                    textAlign: TextAlign.center,
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
    );
  }
}

String _priorityLabel(AnnouncementPriority priority) {
  switch (priority) {
    case AnnouncementPriority.low:
      return 'Low';
    case AnnouncementPriority.normal:
      return 'Normal';
    case AnnouncementPriority.high:
      return 'High';
    case AnnouncementPriority.critical:
      return 'Critical';
  }
}

Color _priorityColor(AnnouncementPriority priority) {
  switch (priority) {
    case AnnouncementPriority.low:
      return BrandColors.accent;
    case AnnouncementPriority.normal:
      return BrandColors.secondary;
    case AnnouncementPriority.high:
      return BrandColors.primary;
    case AnnouncementPriority.critical:
      return const Color(0xFFD7263D);
  }
}
