import '../models/message.dart';

abstract class ChatService {
  Stream<List<Message>> watchChannel(String channelId);

  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  });

  Future<void> markAsRead({
    required String channelId,
    required String messageId,
    required String employeeId,
  });
}



