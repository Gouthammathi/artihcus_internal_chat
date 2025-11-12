import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/message.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/mock/mock_chat_service.dart';
import '../../auth/controllers/auth_controller.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = MockChatService();
  ref.onDispose(service.dispose);
  return service;
});

final chatControllerProvider = StateNotifierProvider.family<
    ChatController, AsyncValue<List<Message>>, String>((ref, channelId) {
  final chatService = ref.watch(chatServiceProvider);
  final authState = ref.watch(authControllerProvider);
  final currentUser = authState.valueOrNull;

  return ChatController(
    chatService: chatService,
    channelId: channelId,
    employeeId: currentUser?.id,
  );
});

class ChatController extends StateNotifier<AsyncValue<List<Message>>> {
  ChatController({
    required ChatService chatService,
    required this.channelId,
    required this.employeeId,
  })  : _chatService = chatService,
        super(const AsyncValue.loading()) {
    _subscription = _chatService.watchChannel(channelId).listen(
      (messages) => state = AsyncValue.data(messages),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
  }

  final ChatService _chatService;
  final String channelId;
  final String? employeeId;

  late final StreamSubscription<List<Message>> _subscription;

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderName,
  }) async {
    await _chatService.sendMessage(
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      content: content,
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    final userId = employeeId;
    if (userId == null) return;

    await _chatService.markAsRead(
      channelId: channelId,
      messageId: messageId,
      employeeId: userId,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}



