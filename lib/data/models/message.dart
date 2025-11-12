import 'package:equatable/equatable.dart';

class Message extends Equatable {
  const Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.readBy,
    this.isPinned = false,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final List<String>? readBy;
  final bool isPinned;

  Message copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? sentAt,
    List<String>? readBy,
    bool? isPinned,
  }) {
    return Message(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      readBy: readBy ?? this.readBy,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'channelId': channelId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'sentAt': sentAt.toIso8601String(),
        'readBy': readBy,
        'isPinned': isPinned,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        channelId: json['channelId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        content: json['content'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
        readBy: (json['readBy'] as List<dynamic>?)?.cast<String>(),
        isPinned: json['isPinned'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        channelId,
        senderId,
        senderName,
        content,
        sentAt,
        readBy,
        isPinned,
      ];
}



