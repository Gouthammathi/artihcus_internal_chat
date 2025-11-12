import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/brand_colors.dart';
import '../../../data/models/support_ticket.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/support_controller.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  SupportTicketStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(supportControllerProvider);
    final employee = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: employee == null ? null : () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  ...SupportTicketStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_statusLabel(status)),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ticketsState.when(
              data: (tickets) {
                final filtered = _filter == null
                    ? tickets
                    : tickets.where((ticket) => ticket.status == _filter).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No support tickets yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
                    return _SupportTicketCard(ticket: ticket);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load support tickets\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    SupportTicketPriority priority = SupportTicketPriority.normal;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Raise support ticket',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Describe the issue',
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Priority'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SupportTicketPriority>(
                        value: priority,
                        isExpanded: true,
                        items: SupportTicketPriority.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => priority = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () async {
                      if (subjectController.text.trim().isEmpty ||
                          descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Subject and description are required.'),
                          ),
                        );
                        return;
                      }

                      await ref.read(supportControllerProvider.notifier).createTicket(
                            subject: subjectController.text.trim(),
                            description: descriptionController.text.trim(),
                            priority: priority,
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    label: const Text('Submit ticket'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return 'Open';
      case SupportTicketStatus.inProgress:
        return 'In progress';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
    }
  }
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({required this.ticket});

  final SupportTicket ticket;

  Color _priorityColor(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.low:
        return Colors.blueGrey;
      case SupportTicketPriority.normal:
        return BrandColors.primary;
      case SupportTicketPriority.high:
        return Colors.orange;
      case SupportTicketPriority.urgent:
        return Colors.redAccent;
    }
  }

  String _priorityLabel(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.low:
        return 'Low';
      case SupportTicketPriority.normal:
        return 'Normal';
      case SupportTicketPriority.high:
        return 'High';
      case SupportTicketPriority.urgent:
        return 'Urgent';
    }
  }

  String _statusLabel(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return 'Open';
      case SupportTicketStatus.inProgress:
        return 'In progress';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, hh:mm a');
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
                    ticket.subject,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text(_priorityLabel(ticket.priority)),
                  backgroundColor:
                      _priorityColor(ticket.priority).withOpacityFraction(0.12),
                  labelStyle: TextStyle(color: _priorityColor(ticket.priority)),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.timelapse, size: 16),
                  label: Text(_statusLabel(ticket.status)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Created by ${ticket.createdBy}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Opened ${dateFormat.format(ticket.createdAt)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
            if (ticket.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ticket.tags
                    .map((tag) => Chip(
                          avatar: const Icon(Icons.tag_outlined, size: 16),
                          label: Text(tag),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

