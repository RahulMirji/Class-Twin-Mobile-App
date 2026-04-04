import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../session/domain/models/student_response.dart';
import '../../../session/domain/session_state.dart';
import '../../../session/presentation/providers/session_provider.dart';
import '../providers/stream_provider.dart';
import '../../data/stream_service.dart';
import 'chat_panel.dart';
import 'hand_raise_modal.dart';
import '../../../../core/providers/system_monitor_provider.dart';

/// StreamScreen — Primary screen for remote students
/// Shows live class feed with question response overlay
class StreamScreen extends ConsumerStatefulWidget {
  const StreamScreen({super.key});

  @override
  ConsumerState<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends ConsumerState<StreamScreen> {
  bool _isPipSwapped = false;
  Alignment _pipAlignment = Alignment.topRight;
  bool _isConnecting = false;
  String? _connectionError;
  StreamSubscription<StreamConnectionState>? _connectionSub;
  StreamSubscription<VideoTrack?>? _cameraSub;
  StreamSubscription<VideoTrack?>? _screenSub;
  VideoTrack? _cameraTrack;
  VideoTrack? _screenTrack;

  @override
  void initState() {
    super.initState();
    // Connect to LiveKit after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToStream();
    });
  }

  Future<void> _connectToStream() async {
    final student = ref.read(currentStudentProvider);
    final sessionId = ref.read(currentSessionIdProvider);

    if (student == null || sessionId == null) {
      setState(() {
        _connectionError = 'Missing student or session info.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      final streamService = ref.read(streamServiceProvider);
      final streamRepo = ref.read(streamRepositoryProvider);

      // Listen for track changes
      _cameraSub = streamService.cameraTrack.listen((track) {
        if (mounted) setState(() => _cameraTrack = track);
      });
      _screenSub = streamService.screenTrack.listen((track) {
        if (mounted) setState(() => _screenTrack = track);
      });
      _connectionSub = streamService.connectionState.listen((state) {
        if (!mounted) return;
        if (state == StreamConnectionState.error) {
          setState(() {
            _isConnecting = false;
            _connectionError = 'Connection lost. Tap to retry.';
          });
        } else if (state == StreamConnectionState.connected) {
          setState(() {
            _isConnecting = false;
            _connectionError = null;
            // Grab any tracks that were already there
            _cameraTrack = streamService.currentCameraTrack;
            _screenTrack = streamService.currentScreenTrack;
          });
        } else if (state == StreamConnectionState.disconnected) {
          setState(() {
            _isConnecting = false;
            _cameraTrack = null;
            _screenTrack = null;
          });
        }
      });

      // Fetch a token from the Edge Function & connect
      final tokenResponse = await streamRepo.fetchToken(
        sessionId: sessionId,
        studentId: student.id,
      );

      await streamService.connect(
        wsUrl: tokenResponse.wsUrl,
        token: tokenResponse.token,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionError = 'Failed to connect: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _cameraSub?.cancel();
    _screenSub?.cancel();
    super.dispose();
  }

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
          if (_cameraTrack != null && _screenTrack != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: _pipAlignment == Alignment.topRight ? 12 : null,
              left: _pipAlignment == Alignment.topLeft ? 12 : null,
              child: GestureDetector(
                onDoubleTap: () =>
                    setState(() => _isPipSwapped = !_isPipSwapped),
                onLongPressMoveUpdate: (details) {
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
                    child: VideoTrackRenderer(
                      _isPipSwapped ? _screenTrack! : _cameraTrack!,
                      fit: VideoViewFit.cover,
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

          // ─── System Banners (Battery / Connection) ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 24,
            right: 24,
            child: Consumer(
              builder: (context, ref, _) {
                final status = ref.watch(systemMonitorProvider);
                return Column(
                  children: [
                    if (status.isLowBattery)
                      _SystemBanner(
                        icon: PhosphorIconsFill.batteryWarning,
                        message: 'Low battery — connect to power.',
                        color: AppTheme.error,
                      ).animate().slideY(begin: -1, end: 0),
                    if (status.isPoorConnection)
                      _SystemBanner(
                        icon: PhosphorIconsFill.wifiSlash,
                        message: 'Unstable connection detected.',
                        color: AppTheme.error,
                      ).animate().slideY(begin: -1, end: 0),
                  ],
                );
              },
            ),
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
    // Dim when question is active and not yet submitted
    final dimmed = streaming?.currentQuestion != null &&
        streaming?.submittedResponse == null;

    // ─── Connecting state ──────────────────
    if (_isConnecting) {
      return Container(
        color: AppTheme.streamBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Connecting to stream...',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Error state ──────────────────────
    if (_connectionError != null) {
      return GestureDetector(
        onTap: _connectToStream,
        child: Container(
          color: AppTheme.streamBackground,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.wifiSlash,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  _connectionError!,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Text(
                    'Tap to retry',
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── Video tracks ─────────────────────
    // Determine which track goes in the main view
    final VideoTrack? mainTrack;
    if (_screenTrack != null && _cameraTrack != null) {
      mainTrack = _isPipSwapped ? _cameraTrack : _screenTrack;
    } else {
      mainTrack = _screenTrack ?? _cameraTrack;
    }

    if (mainTrack != null) {
      return AnimatedOpacity(
        opacity: dimmed ? 0.6 : 1,
        duration: const Duration(milliseconds: 300),
        child: VideoTrackRenderer(
          mainTrack,
          fit: VideoViewFit.contain,
        ),
      );
    }

    // ─── No tracks yet (connected but teacher hasn't started) ───
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
                PhosphorIconsRegular.videoCameraSlash,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Waiting for teacher\'s stream...',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re connected. Video will appear\nwhen the teacher starts streaming.',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseOverlay(SessionStreaming streaming) {
    final question = streaming.currentQuestion!;
    final options = question.options;

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

            // Response buttons (MCQ)
            ...options.map((optionText) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _StreamResponseButton(
                  label: optionText,
                  color: AppTheme.tertiary,
                  onTap: () => _submit(optionText),
                ),
              );
            }),

            if (options.isEmpty)
              // Free-text response fallback  
              TextField(
                onSubmitted: (text) => _submit(text),
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLow,
                  suffixIcon: IconButton(
                    icon: const Icon(PhosphorIconsBold.paperPlaneRight),
                    onPressed: () {},
                  ),
                ),
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

  void _submit(String responseText) {
    ref.read(sessionStateProvider.notifier).submitResponse(responseText);
  }

  Widget _buildSubmittedChip(StudentResponse response) {
    final label = response.response;
    const color = AppTheme.tertiary;

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
            decoration: const BoxDecoration(
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
              // Disconnect from LiveKit
              ref.read(streamServiceProvider).disconnect();
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

class _SystemBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _SystemBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
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
