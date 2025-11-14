import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../../models/message.dart';
import '../chat_service.dart';

class SupabaseChatService implements ChatService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _messagesController = StreamController<List<Message>>.broadcast();
  final _uuid = const Uuid();
  RealtimeChannel? _realtimeChannel;

  SupabaseChatService() {
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    _realtimeChannel = _supabase
        .channel('messages_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            _refreshMessages();
          },
        )
        .subscribe();
  }

  Future<void> _refreshMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:employees!messages_sender_id_fkey(first_name, last_name),
            reads:message_reads(user_id)
          ''')
          .order('created_at', ascending: true);

      final messages = (response as List).map((json) {
        final sender = json['sender'] as Map<String, dynamic>;
        final reads = (json['reads'] as List?)
                ?.map((r) => (r as Map<String, dynamic>)['user_id'] as String)
                .toList() ??
            [];

        return Message(
          id: json['id'] as String,
          channelId: json['channel_id'] as String,
          senderId: json['sender_id'] as String,
          senderName: '${sender['first_name']} ${sender['last_name']}',
          content: json['content'] as String,
          sentAt: DateTime.parse(json['created_at'] as String),
          readBy: reads,
          isPinned: json['is_pinned'] as bool? ?? false,
        );
      }).toList();

      _messagesController.add(messages);
    } catch (e) {
      _messagesController.addError(e);
    }
  }

  @override
  Stream<List<Message>> watchChannel(String channelId) {
    // Initial load
    _refreshMessages();
    return _messagesController.stream
        .map((messages) => messages.where((m) => m.channelId == channelId).toList());
  }

  @override
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'id': _uuid.v4(),
        'channel_id': channelId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead({
    required String channelId,
    required String messageId,
    required String employeeId,
  }) async {
    try {
      await _supabase.from('message_reads').upsert({
        'id': _uuid.v4(),
        'message_id': messageId,
        'user_id': employeeId,
      }, onConflict: 'message_id,user_id');
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _messagesController.close();
  }
}

