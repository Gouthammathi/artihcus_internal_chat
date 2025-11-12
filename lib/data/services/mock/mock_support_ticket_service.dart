import 'dart:async';

import '../../models/support_ticket.dart';
import '../support_ticket_service.dart';
import 'mock_data.dart';

class MockSupportTicketService implements SupportTicketService {
  MockSupportTicketService()
      : _controller = StreamController<List<SupportTicket>>.broadcast() {
    _controller.add(List<SupportTicket>.from(mockTickets));
  }

  final StreamController<List<SupportTicket>> _controller;
  final List<SupportTicket> _buffer = List<SupportTicket>.from(mockTickets);

  @override
  Stream<List<SupportTicket>> watchTickets() => _controller.stream;

  @override
  Future<void> createTicket(SupportTicket ticket) async {
    _buffer.insert(0, ticket);
    _controller.add(List<SupportTicket>.from(_buffer));
  }

  @override
  Future<void> updateTicket(SupportTicket ticket) async {
    final index = _buffer.indexWhere((element) => element.id == ticket.id);
    if (index == -1) return;
    _buffer[index] = ticket;
    _controller.add(List<SupportTicket>.from(_buffer));
  }

  void dispose() {
    _controller.close();
  }
}



