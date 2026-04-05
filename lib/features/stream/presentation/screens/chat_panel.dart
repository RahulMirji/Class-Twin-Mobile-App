import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:class_twin/core/theme.dart';
import 'package:class_twin/features/stream/domain/models/chat_message.dart';
import 'package:class_twin/features/stream/presentation/providers/chat_provider.dart';
import 'package:class_twin/features/session/presentation/providers/session_provider.dart';

/// ChatPanel — Bottom sheet chat drawer
/// PRD Section 7.4
class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId != null) {
      ref.read(chatProvider.notifier).loadMessages(sessionId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final student = ref.read(currentStudentProvider);
    final sessionId = ref.read(currentSessionIdProvider);
    final isAnonymous = ref.read(chatAnonymousProvider);
    if (student == null || sessionId == null) return;

    ref.read(chatProvider.notifier).sendMessage(
          sessionId: sessionId,
          studentId: student.id,
          studentName: student.studentName,
          messageText: text,
        );

    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isAnonymous = ref.watch(chatAnonymousProvider);
    final student = ref.watch(currentStudentProvider);

    // Auto-scroll when messages length changes
    ref.listen(chatProvider.select((s) => s.messages.length), (prev, next) {
      if (next > (prev ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Class Chat',
                        style: AppTheme.titleMedium,
                      ),
                      const Spacer(),
                      // Anonymous toggle
                      Text(
                        'Anonymous',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: isAnonymous,
                          onChanged: (v) =>
                              ref.read(chatAnonymousProvider.notifier).state = v,
                          activeTrackColor: AppTheme.tertiary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                // Message list
                Expanded(
                  child: chatState.messages.isEmpty
                      ? _buildEmptyChat()
                      : _buildMessageList(chatState, student),
                ),
                // Input area
                _buildInputArea(chatState, student),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.chatDots,
            size: 40,
            color: AppTheme.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask a question...',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState chatState, dynamic student) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final msg = chatState.messages[index];
        final isOwn = msg.studentId == student?.id;
        return _ChatBubble(
          message: msg,
          isOwn: isOwn,
        );
      },
    );
  }

  Widget _buildInputArea(ChatState chatState, dynamic student) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: TextField(
                  controller: _messageController,
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    hintStyle:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: false,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: chatState.canSend ? _send : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      chatState.canSend ? AppTheme.tertiary : AppTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsBold.arrowUp,
                  size: 16,
                  color: chatState.canSend
                      ? AppTheme.onTertiary
                      : AppTheme.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;

  const _ChatBubble({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final isTeacher = message.isTeacher;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Name Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTeacher) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TEACHER',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.onSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  message.isAnonymous ? 'Anonymous' : message.studentName,
                  style: AppTheme.labelSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: message.isAnonymous
                        ? AppTheme.textTertiary
                        : AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn
                    ? AppTheme.surfaceContainerLow
                    : (isTeacher
                        ? AppTheme.primaryContainer.withValues(alpha: 0.1)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: isTeacher
                    ? Border.all(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.2))
                    : null,
              ),
              child: Text(
                message.messageText,
                textAlign: isTeacher ? TextAlign.center : TextAlign.start,
                style: AppTheme.bodyMedium.copyWith(
                  color: isTeacher ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: isTeacher ? FontWeight.w500 : null,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Timestamp
            Text(
              _formatTime(message.sentAt),
              style: AppTheme.labelSmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
