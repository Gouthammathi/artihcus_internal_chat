import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../models/support_ticket.dart';
import '../support_ticket_service.dart';

class SupabaseSupportTicketService implements SupportTicketService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _ticketsController = StreamController<List<SupportTicket>>.broadcast();
  RealtimeChannel? _realtimeChannel;

  SupabaseSupportTicketService() {
    _subscribeToTickets();
  }

  void _subscribeToTickets() {
    _realtimeChannel = _supabase
        .channel('support_tickets_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_tickets',
          callback: (payload) {
            _refreshTickets();
          },
        )
        .subscribe();
  }

  Future<void> _refreshTickets() async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);

      final tickets = (response as List).map((json) {
        return SupportTicket(
          id: json['id'] as String,
          subject: json['subject'] as String,
          description: json['description'] as String,
          status: SupportTicketStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => SupportTicketStatus.open,
          ),
          priority: SupportTicketPriority.values.firstWhere(
            (p) => p.name == json['priority'],
            orElse: () => SupportTicketPriority.normal,
          ),
          createdBy: json['created_by'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
          assignedTo: json['assigned_to'] as String?,
          tags: (json['tags'] as List?)?.cast<String>() ?? [],
        );
      }).toList();

      _ticketsController.add(tickets);
    } catch (e) {
      _ticketsController.addError(e);
    }
  }

  @override
  Stream<List<SupportTicket>> watchTickets() {
    // Initial load
    _refreshTickets();
    return _ticketsController.stream;
  }

  @override
  Future<void> createTicket(SupportTicket ticket) async {
    try {
      await _supabase.from('support_tickets').insert({
        'id': ticket.id,
        'subject': ticket.subject,
        'description': ticket.description,
        'status': ticket.status.name,
        'priority': ticket.priority.name,
        'created_by': ticket.createdBy,
        'assigned_to': ticket.assignedTo,
        'tags': ticket.tags,
      });
    } catch (e) {
      throw Exception('Failed to create ticket: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTicket(SupportTicket ticket) async {
    try {
      await _supabase.from('support_tickets').update({
        'subject': ticket.subject,
        'description': ticket.description,
        'status': ticket.status.name,
        'priority': ticket.priority.name,
        'assigned_to': ticket.assignedTo,
        'tags': ticket.tags,
      }).eq('id', ticket.id);
    } catch (e) {
      throw Exception('Failed to update ticket: ${e.toString()}');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _ticketsController.close();
  }
}

