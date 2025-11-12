import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/brand_colors.dart';
import '../../../data/models/project.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);

    return projectsState.when(
      data: (projects) {
        final onTrack = projects.where((p) => p.status == ProjectStatus.onTrack).length;
        final atRisk = projects.where((p) => p.status == ProjectStatus.atRisk).length;
        final blocked = projects.where((p) => p.status == ProjectStatus.blocked).length;
        final completed = projects.where((p) => p.status == ProjectStatus.completed).length;

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _MetricsRow(
                metrics: [
                  _Metric(
                    title: 'On track',
                    value: onTrack,
                    color: Colors.teal,
                  ),
                  _Metric(
                    title: 'At risk',
                    value: atRisk,
                    color: Colors.orange,
                  ),
                  _Metric(
                    title: 'Blocked',
                    value: blocked,
                    color: Colors.redAccent,
                  ),
                  _Metric(
                    title: 'Completed',
                    value: completed,
                    color: BrandColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Active projects',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...projects.map((project) => _ProjectCard(project: project)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Unable to load dashboard\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final itemWidth = isWide
            ? (constraints.maxWidth - 48) / metrics.length
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: isWide ? itemWidth : double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.title,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            metric.value.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: metric.color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final Project project;

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.onTrack:
        return Colors.teal;
      case ProjectStatus.atRisk:
        return Colors.orange;
      case ProjectStatus.blocked:
        return Colors.redAccent;
      case ProjectStatus.completed:
        return BrandColors.primary;
    }
  }

  String _statusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.onTrack:
        return 'On track';
      case ProjectStatus.atRisk:
        return 'At risk';
      case ProjectStatus.blocked:
        return 'Blocked';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDateFormat = DateFormat('MMM d, yyyy');
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
                    project.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(project.status)),
                  backgroundColor:
                      _statusColor(project.status).withOpacityFraction(0.12),
                  labelStyle: TextStyle(color: _statusColor(project.status)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: project.progress,
              backgroundColor: BrandColors.subtleBorder,
              color: BrandColors.primary,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(project.progress * 100).toStringAsFixed(0)}% complete • Due ${project.dueDate != null ? dueDateFormat.format(project.dueDate!) : 'TBD'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: project.milestones
                  .map((milestone) => Chip(
                        avatar: const Icon(Icons.flag_outlined, size: 16),
                        label: Text(milestone),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

