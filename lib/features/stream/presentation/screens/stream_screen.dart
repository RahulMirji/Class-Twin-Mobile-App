import 'dart:async';
import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../session/domain/models/student_response.dart';
import '../../../session/domain/session_state.dart';
import '../../../session/presentation/providers/session_provider.dart';
import '../providers/stream_provider.dart';
import '../../../engagement/presentation/providers/engagement_provider.dart';
import '../../data/stream_service.dart';
import 'chat_panel.dart';
import 'hand_raise_modal.dart';
import 'widgets/confidence_slider.dart';
import '../../../../core/providers/system_monitor_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/translation_provider.dart';
import 'widgets/live_caption_overlay.dart';

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
    final tr = ref.read(trProvider);
    final student = ref.read(currentStudentProvider);
    final sessionId = ref.read(currentSessionIdProvider);

    if (student == null || sessionId == null) {
      setState(() {
        _connectionError = tr.get('missing_student_info');
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
            _connectionError = tr.get('connection_lost_retry');
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

      // Start engagement tracking
      final engagementService = ref.read(engagementServiceProvider);
      await engagementService.start(
        sessionId: sessionId,
        studentId: student.id,
        getAppMetrics: () {
          final s = ref.read(currentStudentProvider);
          return {
            'device_orientation': MediaQuery.of(context).orientation.name,
            'network_quality': 'good',
            'confidence_slider': s?.manualConfidence ?? 50,
          };
        },
      );

      // Start live translation listener
      final translationService = ref.read(translationServiceProvider);

      // Fetch the student's actual language from DB (SharedPreferences may default to 'en')
      String preferredLang = ref.read(localeProvider);
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser?.email != null) {
          final resp = await Supabase.instance.client
              .from('students')
              .select('language')
              .eq('email', currentUser!.email!)
              .maybeSingle();
          if (resp != null && resp['language'] != null && resp['language'] != '') {
            preferredLang = resp['language'];
            // Sync DB language to local locale so it persists
            ref.read(localeProvider.notifier).setLocale(preferredLang);
          }
        }
      } catch (e) {
        dev.log('[Translation] Could not fetch DB language, using local: $preferredLang');
      }

      translationService.setLanguage(preferredLang);
      translationService.subscribe(sessionId);

      // Mute original teacher audio when TTS translation is active
      // (student should only hear translated voice, not both)
      if (preferredLang != 'en' && translationService.ttsEnabled) {
        streamService.muteRemoteAudio();
        dev.log('[Translation] Muted original audio — TTS active for $preferredLang');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionError = '${tr.get('failed_connect')}: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _cameraSub?.cancel();
    _screenSub?.cancel();
    
    // Stop engagement tracking
    try {
      ref.read(engagementServiceProvider).stop();
    } catch (_) {
      // ref might already be disposed, ignore
    }
    
    // Stop translation service
    try {
      ref.read(translationServiceProvider).unsubscribe();
    } catch (_) {}
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final sessionState = ref.watch(sessionStateProvider);

    SessionStreaming? streaming;
    if (sessionState is SessionStreaming) {
      streaming = sessionState;
      // Update engagement tracking round
      if (streaming.roundNumber != null) {
        ref.read(engagementServiceProvider).updateRound(streaming.roundNumber!);
      }
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
            child: _buildStreamView(streaming, tr),
          ),

          // ─── Confidence Slider ───────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 24,
            right: 24,
            child: const ConfidenceSlider(),
          ),

          // ─── Local Student Camera (Engagement) ──────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 84,
            left: _pipAlignment == Alignment.topRight ? 12 : null,
            right: _pipAlignment == Alignment.topLeft ? 12 : null,
            child: ValueListenableBuilder<CameraController?>(
              valueListenable: ref.read(engagementServiceProvider).cameraControllerNotifier,
              builder: (context, controller, _) {
                if (controller == null) return const SizedBox.shrink();
                return Container(
                  width: 80,
                  height: 106,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    // Flip horizontally since it's a front camera
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159), // math.pi
                      child: CameraPreview(controller),
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── PiP Camera ──────────────────────────────
          if (_cameraTrack != null && _screenTrack != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 84,
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
            _buildResponseOverlay(streaming!, tr),

          // ─── Submitted Response Mini Panel ─────────────
          if (hasSubmitted)
            Positioned(
              bottom: 64 + MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: _buildSubmittedChip(streaming!.submittedResponse!, tr),
            ),

          // ─── Live Translation Captions ──────────────
          Positioned(
            bottom: 64 + MediaQuery.of(context).padding.bottom + (hasSubmitted ? 70 : (hasQuestion && !hasSubmitted ? 320 : 16)),
            left: 0,
            right: 0,
            child: LiveCaptionOverlay(
              translationService: ref.read(translationServiceProvider),
              preferredLanguage: ref.watch(localeProvider),
            ),
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
                        message: tr.get('low_battery'),
                        color: AppTheme.error,
                      ).animate().slideY(begin: -1, end: 0),
                    if (status.isPoorConnection)
                      _SystemBanner(
                        icon: PhosphorIconsFill.wifiSlash,
                        message: tr.get('unstable_connection'),
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
            child: _buildControlBar(context, tr),
          ),

          // ─── AI Telemetry Pulsar ──────────────────────
          Positioned(
            bottom: 64 + MediaQuery.of(context).padding.bottom + 12,
            right: 16,
            child: _AITelemetryIndicator(tr: tr),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamView(SessionStreaming? streaming, dynamic tr) {
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
                tr.get('connecting_stream'),
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
                    tr.get('tap_retry'),
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
                tr.get('waiting_teacher_stream'),
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr.get('connected_wait_video'),
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

  Widget _buildResponseOverlay(SessionStreaming streaming, dynamic tr) {
    final question = streaming.currentQuestion!;
    final currentIndex = streaming.currentIndex ?? 0;
    final totalQuestions = streaming.questions?.length ?? 1;
    final options = question.options;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr.get('question').toUpperCase()} ${currentIndex + 1} ${tr.get('of').toUpperCase()} $totalQuestions',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tr.get('live').toUpperCase(),
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Timer bar (visual only for now)
            Container(
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.7, // Simulated time
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Question text
            Text(
              question.questionText,
              style: AppTheme.displaySmall.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Response buttons (MCQ)
            ...options.map((optionText) {
              final isSelected = streaming.submittedResponse?.response == optionText;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _StreamResponseButton(
                  label: optionText,
                  color: isSelected ? AppTheme.primary : AppTheme.tertiary,
                  isSelected: isSelected,
                  onTap: isSelected ? () {} : () => _submit(optionText),
                ),
              );
            }),

            if (options.isEmpty)
              // Free-text response fallback  
              TextField(
                onSubmitted: (text) => _submit(text),
                decoration: InputDecoration(
                  hintText: tr.get('type_response'),
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
                  tr.get('add_detail'),
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

  Widget _buildSubmittedChip(StudentResponse response, dynamic tr) {
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
          Expanded(
            child: Text(
              label,
              style: AppTheme.labelMedium.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              // Undo — future implementation
            },
            child: Text(
              tr.get('undo'),
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3);
  }

  Widget _buildControlBar(BuildContext context, dynamic tr) {
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
          // Mic Toggle
          StreamBuilder<bool>(
            stream: ref.read(streamServiceProvider).micState,
            initialData: ref.read(streamServiceProvider).isMicEnabled,
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? false;
              return _ControlButton(
                icon: isEnabled
                    ? PhosphorIconsBold.microphone
                    : PhosphorIconsBold.microphoneSlash,
                label: isEnabled ? tr.get('mute') : tr.get('unmute'),
                onTap: () => ref.read(streamServiceProvider).toggleMicrophone(),
                color: isEnabled ? AppTheme.primary : AppTheme.textPrimary,
              );
            },
          ),

          const SizedBox(width: 16),

          // Raise Hand
          _ControlButton(
            icon: PhosphorIconsBold.handPalm,
            label: tr.get('raise_hand'),
            onTap: () => _showHandRaise(context),
          ),

          const SizedBox(width: 16),

          // Chat
          _ControlButton(
            icon: PhosphorIconsBold.chatDots,
            label: tr.get('chat'),
            onTap: () => _showChat(context),
          ),

          const SizedBox(width: 16),

          // Translation TTS Toggle
          _ControlButton(
            icon: PhosphorIconsBold.translate,
            label: 'TTS',
            onTap: () {
              final ts = ref.read(translationServiceProvider);
              ts.toggleTts();
              // Mute/unmute original audio based on TTS state
              final streamService = ref.read(streamServiceProvider);
              if (ts.ttsEnabled && ts.preferredLanguage != 'en') {
                streamService.muteRemoteAudio();
              } else {
                streamService.unmuteRemoteAudio();
              }
              setState(() {}); // Refresh button color
            },
            color: ref.read(translationServiceProvider).ttsEnabled
                ? AppTheme.primary
                : AppTheme.textPrimary,
          ),

          const Spacer(),

          // Leave
          TextButton(
            onPressed: () {
              // Stop translation
              ref.read(translationServiceProvider).unsubscribe();
              // Disconnect from LiveKit
              ref.read(streamServiceProvider).disconnect();
              ref.read(sessionStateProvider.notifier).leaveSession();
              context.go('/');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: Text(tr.get('leave')),
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
  final bool isSelected;

  const _StreamResponseButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isSelected ? AppTheme.primary : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelLarge.copyWith(
            color: isSelected ? AppTheme.primary : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.textPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
class _AITelemetryIndicator extends StatelessWidget {
  final dynamic tr;
  const _AITelemetryIndicator({required this.tr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Pulsing "Data Source"
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                duration: 1.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.5, 1.5),
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 1.seconds),
          const SizedBox(width: 8),
          
          // Technical Label
          Text(
            tr.get('ai_analysis_active'),
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.primary.withValues(alpha: 0.9),
              letterSpacing: 0.8,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // "Collecting" Data Nodes
          Row(
            children: List.generate(3, (index) {
              return Container(
                width: 2,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeOut(
                    delay: (index * 200).ms,
                    duration: 600.ms,
                  )
                  .fadeIn(
                    delay: (index * 200).ms,
                    duration: 600.ms,
                  );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideX(begin: 0.5, curve: Curves.easeOutCubic);
  }
}
