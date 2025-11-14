import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/support_ticket.dart';
import '../../../data/services/support_ticket_service.dart';
import '../../../data/services/supabase/supabase_support_ticket_service.dart';
import '../../auth/controllers/auth_controller.dart';

final supportTicketServiceProvider = Provider<SupportTicketService>((ref) {
  final service = SupabaseSupportTicketService();
  ref.onDispose(service.dispose);
  return service;
});

final supportControllerProvider = StateNotifierProvider<SupportController,
    AsyncValue<List<SupportTicket>>>((ref) {
  final service = ref.watch(supportTicketServiceProvider);
  final employee = ref.watch(authControllerProvider).valueOrNull;

  return SupportController(
    supportTicketService: service,
    currentEmployeeId: employee?.id,
  );
});

class SupportController extends StateNotifier<AsyncValue<List<SupportTicket>>> {
  SupportController({
    required SupportTicketService supportTicketService,
    required this.currentEmployeeId,
  })  : _supportTicketService = supportTicketService,
        super(const AsyncValue.loading()) {
    _subscription = _supportTicketService.watchTickets().listen(
      (tickets) => state = AsyncValue.data(tickets),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
  }

  final SupportTicketService _supportTicketService;
  final String? currentEmployeeId;
  final Uuid _uuid = const Uuid();
  late final StreamSubscription<List<SupportTicket>> _subscription;

  Future<void> createTicket({
    required String subject,
    required String description,
    required SupportTicketPriority priority,
    List<String> tags = const [],
  }) async {
    final creator = currentEmployeeId;
    if (creator == null) {
      throw StateError('You must be signed in to create a support ticket.');
    }

    final ticket = SupportTicket(
      id: _uuid.v4(),
      subject: subject,
      description: description,
      status: SupportTicketStatus.open,
      priority: priority,
      createdBy: creator,
      createdAt: DateTime.now(),
      tags: tags,
    );

    await _supportTicketService.createTicket(ticket);
  }

  Future<void> updateTicket(SupportTicket ticket) async {
    await _supportTicketService.updateTicket(ticket);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}



