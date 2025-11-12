import '../models/support_ticket.dart';

abstract class SupportTicketService {
  Stream<List<SupportTicket>> watchTickets();

  Future<void> createTicket(SupportTicket ticket);

  Future<void> updateTicket(SupportTicket ticket);
}



