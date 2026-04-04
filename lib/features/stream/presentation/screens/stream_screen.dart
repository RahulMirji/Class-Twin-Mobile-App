import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../session/domain/models/student_response.dart';
import '../../../session/domain/session_state.dart';
import '../../../session/presentation/providers/session_provider.dart';
import 'chat_panel.dart';
import 'hand_raise_modal.dart';

/// StreamScreen — Primary screen for remote students
/// Shows live class feed with response overlay
class StreamScreen extends ConsumerStatefulWidget {
  const StreamScreen({super.key});

  @override
  ConsumerState<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends ConsumerState<StreamScreen> {
  bool _isPipSwapped = false;
  Alignment _pipAlignment = Alignment.topRight;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);

    SessionStreaming? streaming;
    if (sessionState is SessionStreaming) {
      streaming = sessionState;
    }

    final hasQuestion = streaming?.currentQuestion != null;
    final hasSubmitted = streaming?.submittedResponse != null;

    return Scaffold(
      backgroundColor: AppTheme.streamBackground,
      body: Stack(
        children: [
          // ─── Main Video Area ─────────────────────────
          Positioned.fill(
            bottom: 64 + MediaQuery.of(context).padding.bottom,
            child: _buildStreamView(streaming),
          ),

          // ─── PiP Camera ──────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: _pipAlignment == Alignment.topRight ? 12 : null,
            left: _pipAlignment == Alignment.topLeft ? 12 : null,
            child: GestureDetector(
              onDoubleTap: () =>
                  setState(() => _isPipSwapped = !_isPipSwapped),
              onLongPressMoveUpdate: (details) {
                // Draggable PiP
                if (details.globalPosition.dx <
                    MediaQuery.of(context).size.width / 2) {
                  setState(() => _pipAlignment = Alignment.topLeft);
                } else {
                  setState(() => _pipAlignment = Alignment.topRight);
                }
              },
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    color: AppTheme.inverseSurface,
                    child: Center(
                      child: Icon(
                        _isPipSwapped 
                            ? PhosphorIconsRegular.presentation
                            : PhosphorIconsRegular.user,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Response Panel (slides up on question) ──
          if (hasQuestion && !hasSubmitted)
            _buildResponseOverlay(streaming!),

          // ─── Submitted Response Mini Panel ─────────────
          if (hasSubmitted)
            Positioned(
              bottom: 64 + MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: _buildSubmittedChip(streaming!.submittedResponse!),
            ),

          // ─── Bottom Control Bar ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamView(SessionStreaming? streaming) {
    // Dim when question is active
    final dimmed = streaming?.currentQuestion != null &&
        streaming?.submittedResponse == null;

    return AnimatedOpacity(
      opacity: dimmed ? 0.6 : 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: AppTheme.streamBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.presentation,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Teacher\'s Stream',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'LiveKit video will render here',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseOverlay(SessionStreaming streaming) {
    final question = streaming.currentQuestion!;

    return Positioned(
      bottom: 64 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer bar
            Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.tertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Question text
            Text(
              question.questionText,
              style: AppTheme.headlineMedium,
            ),

            const SizedBox(height: 20),

            // Response buttons
            _StreamResponseButton(
              label: 'Got It',
              color: AppTheme.responseGotIt,
              onTap: () => _submit(ResponseType.gotIt),
            ),
            const SizedBox(height: 8),
            _StreamResponseButton(
              label: 'Somewhat',
              color: AppTheme.responseSomewhat,
              onTap: () => _submit(ResponseType.somewhat),
            ),
            const SizedBox(height: 8),
            _StreamResponseButton(
              label: 'Lost',
              color: AppTheme.responseLost,
              onTap: () => _submit(ResponseType.lost),
            ),

            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Add detail',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.tertiary),
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 320.ms, curve: Curves.easeOutCubic),
    );
  }

  void _submit(ResponseType type) {
    ref.read(sessionStateProvider.notifier).submitResponse(type);
  }

  Widget _buildSubmittedChip(StudentResponse response) {
    final color = switch (response.response) {
      ResponseType.gotIt => AppTheme.responseGotIt,
      ResponseType.somewhat => AppTheme.responseSomewhat,
      ResponseType.lost => AppTheme.responseLost,
    };

    final label = switch (response.response) {
      ResponseType.gotIt => 'Got It ✓',
      ResponseType.somewhat => 'Somewhat',
      ResponseType.lost => 'Lost',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.labelMedium.copyWith(color: color)),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Undo — future implementation
            },
            child: Text(
              'Undo',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3);
  }

  Widget _buildControlBar(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Raise Hand
          _ControlButton(
            icon: PhosphorIconsBold.handPalm,
            label: 'Raise Hand',
            onTap: () => _showHandRaise(context),
          ),

          const SizedBox(width: 16),

          // Chat
          _ControlButton(
            icon: PhosphorIconsBold.chatDots,
            label: 'Chat',
            onTap: () => _showChat(context),
          ),

          const Spacer(),

          // Leave
          TextButton(
            onPressed: () {
              ref.read(sessionStateProvider.notifier).leaveSession();
              context.go('/');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatPanel(),
    );
  }

  void _showHandRaise(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const HandRaiseModal(),
    );
  }
}

class _StreamResponseButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StreamResponseButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: Text(label, style: AppTheme.labelLarge.copyWith(color: color)),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textPrimary),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.labelMedium),
        ],
      ),
    );
  }
}
