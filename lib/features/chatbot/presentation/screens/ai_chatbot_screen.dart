import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chatbot_provider.dart';

class AiChatbotScreen extends ConsumerStatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  ConsumerState<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends ConsumerState<AiChatbotScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(chatMessagesProvider.notifier).sendMessage(text);

    // Scroll to bottom after a short delay for the new message to render
    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSuggestionTap(String suggestion) {
    _textController.text = suggestion;
    _sendMessage();
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Icon(PhosphorIconsRegular.trash, color: AppTheme.error, size: 24),
            const SizedBox(width: 12),
            Text('Clear Chat', style: AppTheme.titleLarge),
          ],
        ),
        content: Text(
          'This will delete your entire conversation history. This action cannot be undone.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clearConversation();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // ─── Header ──────────────────────────────────────────
          _buildHeader(messagesAsync),

          // ─── Chat Body ───────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              data: (messages) => messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(messages),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.warning,
                        size: 48, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text('Something went wrong', style: AppTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$err', style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),

          // ─── Input Bar ───────────────────────────────────────
          _buildInputBar(bottomPad),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(AsyncValue<List<ChatMessage>> messagesAsync) {
    final hasMessages =
        messagesAsync.valueOrNull != null && messagesAsync.valueOrNull!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
          child: Row(
            children: [
              // Bot avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.tertiary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  PhosphorIconsFill.robot,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Doubt Solver',
                      style: AppTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ask doubts in any language',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Clear button
              if (hasMessages)
                IconButton(
                  onPressed: _showClearDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerLowest,
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: Icon(
                    PhosphorIconsRegular.trash,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Empty State — with suggestion chips
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          // Illustration
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.tertiaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.chatsCircle,
              size: 44,
              color: AppTheme.tertiary.withValues(alpha: 0.7),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            'Your personal AI tutor',
            style: AppTheme.displaySmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 10),

          Text(
            'Ask any doubt in your language — English, हिन्दी, ಕನ್ನಡ, தமிழ் — and get instant explanations.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 36),

          // Suggestion chips
          Text(
            'Try asking:',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              _SuggestionChip(
                text: 'Explain photosynthesis',
                onTap: () => _onSuggestionTap('Explain photosynthesis'),
                delay: 350,
              ),
              _SuggestionChip(
                text: 'Solve: 2x + 3 = 7',
                onTap: () => _onSuggestionTap('Solve: 2x + 3 = 7'),
                delay: 400,
              ),
              _SuggestionChip(
                text: 'न्यूटन के नियम समझाओ',
                onTap: () => _onSuggestionTap('न्यूटन के नियम समझाओ'),
                delay: 450,
              ),
              _SuggestionChip(
                text: 'What is mitosis?',
                onTap: () => _onSuggestionTap('What is mitosis?'),
                delay: 500,
              ),
              _SuggestionChip(
                text: 'ಗುರುತ್ವಾಕರ್ಷಣೆ ಎಂದರೇನು?',
                onTap: () => _onSuggestionTap('ಗುರುತ್ವಾಕರ್ಷಣೆ ಎಂದರೇನು?'),
                delay: 550,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Message List
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMessageList(List<ChatMessage> messages) {
    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showAvatar = !message.isUser &&
            (index == 0 || messages[index - 1].isUser);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: message.isUser
              ? _UserBubble(message: message)
              : _AiBubble(
                  message: message,
                  showAvatar: showAvatar,
                  onRetry: message.status == MessageStatus.error
                      ? () => ref
                          .read(chatMessagesProvider.notifier)
                          .retryMessage(message.id)
                      : null,
                ),
        )
            .animate()
            .fadeIn(duration: 250.ms)
            .slideY(begin: 0.08, end: 0, duration: 250.ms);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Input Bar
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInputBar(double bottomPad) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      // Account for bottom nav bar padding
      padding: EdgeInsets.fromLTRB(12, 10, 12, bottomPad > 0 ? 84 + bottomPad : 92),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your doubt...',
                        hintStyle: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hasText ? AppTheme.primary : AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              boxShadow: _hasText ? AppTheme.ambientShadowWarm : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasText ? _sendMessage : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: Icon(
                  PhosphorIconsFill.paperPlaneRight,
                  color: _hasText ? Colors.white : AppTheme.textTertiary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Chat Bubbles
// ═════════════════════════════════════════════════════════════════════

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.text,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final VoidCallback? onRetry;

  const _AiBubble({
    required this.message,
    required this.showAvatar,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isError = message.status == MessageStatus.error;
    final isSending = message.status == MessageStatus.sending;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bot avatar
        if (showAvatar)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.tertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              PhosphorIconsFill.robot,
              color: Colors.white,
              size: 16,
            ),
          )
        else
          const SizedBox(width: 32),

        const SizedBox(width: 10),

        // Message content
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError
                  ? AppTheme.errorContainer.withValues(alpha: 0.5)
                  : AppTheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isError
                    ? AppTheme.error.withValues(alpha: 0.3)
                    : AppTheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSending
                ? _TypingIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      SelectableText(
                        message.text,
                        style: AppTheme.bodyMedium.copyWith(
                          color: isError
                              ? AppTheme.error
                              : AppTheme.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      // Retry button for errors
                      if (isError && onRetry != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onRetry,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsRegular.arrowClockwise,
                                  size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to retry',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Typing Indicator (animated dots)
// ═════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: _BouncingDot(delay: index * 150),
        );
      }),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Suggestion Chip
// ═════════════════════════════════════════════════════════════════════

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final int delay;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Text(
          text,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0, delay: delay.ms, duration: 300.ms);
  }
}
