import 'dart:async';

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../models/message.dart';
import '../chat_service.dart';
import 'mock_data.dart';

class MockChatService implements ChatService {
  MockChatService() {
    for (final entry in mockMessagesByChannel.entries) {
      _controllers[entry.key] = StreamController<List<Message>>.broadcast();
      _buffers[entry.key] = List<Message>.from(entry.value);
    }
  }

  final uuid = const Uuid();
  final Map<String, StreamController<List<Message>>> _controllers = {};
  final Map<String, List<Message>> _buffers = {};

  @override
  Stream<List<Message>> watchChannel(String channelId) {
    _ensureChannel(channelId);
    return _controllers[channelId]!.stream.map(
      (messages) => messages.sortedBy<DateTime>((message) => message.sentAt).toList(),
    );
  }

  @override
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    _ensureChannel(channelId);

    final message = Message(
      id: uuid.v4(),
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
      readBy: [senderId],
    );

    final buffer = _buffers[channelId]!;
    buffer.add(message);
    _controllers[channelId]!.add(List<Message>.from(buffer));
  }

  @override
  Future<void> markAsRead({
    required String channelId,
    required String messageId,
    required String employeeId,
  }) async {
    final buffer = _buffers[channelId];
    if (buffer == null) return;

    final index = buffer.indexWhere((message) => message.id == messageId);
    if (index == -1) return;

    final message = buffer[index];
    final updated = message.copyWith(
      readBy: {...?message.readBy, employeeId}.toList(),
    );
    buffer[index] = updated;
    _controllers[channelId]?.add(List<Message>.from(buffer));
  }

  void _ensureChannel(String channelId) {
    _buffers.putIfAbsent(channelId, () => <Message>[]);
    _controllers.putIfAbsent(
      channelId,
      () {
        final controller = StreamController<List<Message>>.broadcast();
        final seed = mockMessagesByChannel[channelId];
        if (seed != null) {
          _buffers[channelId] = List<Message>.from(seed);
          controller.add(List<Message>.from(seed));
        }
        return controller;
      },
    );
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}



