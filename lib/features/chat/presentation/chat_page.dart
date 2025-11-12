import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/brand_colors.dart';
import '../../../data/models/message.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  static const String _channelId = 'general';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final auth = ref.read(authControllerProvider);
    final employee = auth.valueOrNull;
    if (employee == null) return;

    await ref.read(chatControllerProvider(_channelId).notifier).sendMessage(
          content: content,
          senderId: employee.id,
          senderName: employee.fullName,
        );
    _messageController.clear();

    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(_channelId));
    final auth = ref.watch(authControllerProvider);
    final employee = auth.valueOrNull;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.primary.withOpacityFraction(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: BrandColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#general',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Company-wide updates and collaboration',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (chatState.hasValue)
                Chip(
                  label: Text('${chatState.value!.length} messages'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: chatState.when(
            data: (messages) {
              final sorted = List<Message>.from(messages)
                ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final message = sorted[index];
                  final isMine = message.senderId == employee?.id;
                  return Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMine
                            ? BrandColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomLeft: Radius.circular(isMine ? 16 : 4),
                          bottomRight: Radius.circular(isMine ? 4 : 16),
                        ),
                        border: Border.all(
                          color: isMine
                              ? Colors.transparent
                              : BrandColors.subtleBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacityFraction(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMine)
                            Text(
                              message.senderName,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: BrandColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          Text(
                            message.content,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isMine ? Colors.white : BrandColors.neutralForeground,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: isMine ? Colors.white70 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _timeFormat.format(message.sentAt),
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isMine ? Colors.white70 : Colors.black45,
                                        ),
                              ),
                              if (isMine && message.readBy != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.done_all,
                                    size: 16,
                                    color: message.readBy!.length > 1
                                        ? Colors.lightGreenAccent
                                        : Colors.white70),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Unable to load messages\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Message #general',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: employee == null ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

