import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme.dart';
import '../../data/translation_service.dart';

/// LiveCaptionOverlay — displays translated teacher speech as subtitles
/// overlaid on the video stream.
class LiveCaptionOverlay extends StatefulWidget {
  final TranslationService translationService;
  final String preferredLanguage;

  const LiveCaptionOverlay({
    super.key,
    required this.translationService,
    required this.preferredLanguage,
  });

  @override
  State<LiveCaptionOverlay> createState() => _LiveCaptionOverlayState();
}

class _LiveCaptionOverlayState extends State<LiveCaptionOverlay> {
  LiveTranslation? _currentCaption;
  StreamSubscription<LiveTranslation>? _sub;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _sub = widget.translationService.captions.listen(_onCaption);
  }

  void _onCaption(LiveTranslation translation) {
    if (!mounted) return;
    setState(() => _currentCaption = translation);

    // Auto-hide after 8 seconds
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _currentCaption = null);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCaption == null || !widget.translationService.captionsEnabled) {
      return const SizedBox.shrink();
    }

    final translation = _currentCaption!;
    final translatedText = translation.getForLanguage(widget.preferredLanguage);
    final showOriginal = widget.preferredLanguage != translation.sourceLang;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text (small, faded)
          if (showOriginal)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                translation.originalText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Translated text (bold, prominent)
          Text(
            translatedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          // Language badge
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE TRANSLATION',
                style: TextStyle(
                  color: AppTheme.primary.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }
}
