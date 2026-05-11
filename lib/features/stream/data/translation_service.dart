import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for a single live translation event
class LiveTranslation {
  final String originalText;
  final String sourceLang;
  final Map<String, String> translations;
  final DateTime createdAt;

  LiveTranslation({
    required this.originalText,
    required this.sourceLang,
    required this.translations,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get translated text for a specific language, falling back to original
  String getForLanguage(String langCode) {
    return translations[langCode] ?? originalText;
  }

  factory LiveTranslation.fromJson(Map<String, dynamic> json) {
    final rawTranslations = json['translations'];
    final Map<String, String> parsed = {};
    if (rawTranslations is Map) {
      rawTranslations.forEach((key, value) {
        parsed[key.toString()] = value.toString();
      });
    }

    return LiveTranslation(
      originalText: json['original_text'] as String? ?? '',
      sourceLang: json['source_lang'] as String? ?? 'en',
      translations: parsed,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// TTS language code mapping (BCP 47 format)
const _ttsLangMap = <String, String>{
  'en': 'en-IN',
  'hi': 'hi-IN',
  'kn': 'kn-IN',
  'ta': 'ta-IN',
  'te': 'te-IN',
  'ml': 'ml-IN',
  'mr': 'mr-IN',
  'gu': 'gu-IN',
  'bn': 'bn-IN',
};

/// TranslationService — listens to live_translations via Supabase Realtime
/// and plays them aloud using Flutter TTS.
class TranslationService {
  final SupabaseClient _client;
  final FlutterTts _tts;

  RealtimeChannel? _channel;
  String _preferredLanguage = 'en';
  bool _ttsEnabled = true;
  bool _captionsEnabled = true;
  bool _isSpeaking = false;
  final Queue<String> _speechQueue = Queue<String>();

  // Stream controllers for UI
  final _captionController = StreamController<LiveTranslation>.broadcast();
  final _ttsStateController = StreamController<bool>.broadcast();

  Stream<LiveTranslation> get captions => _captionController.stream;
  Stream<bool> get ttsState => _ttsStateController.stream;

  bool get ttsEnabled => _ttsEnabled;
  bool get captionsEnabled => _captionsEnabled;
  String get preferredLanguage => _preferredLanguage;

  TranslationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _tts = FlutterTts() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.55); // Faster for near-realtime feel
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _tts.setErrorHandler((msg) {
      dev.log('[TTS] Error: $msg', name: 'TranslationService');
      _isSpeaking = false;
      _processQueue();
    });
  }

  /// Start listening for translations for a session
  void subscribe(String sessionId) {
    // Unsubscribe from previous session
    unsubscribe();

    dev.log('[Translation] Subscribing to session: $sessionId',
        name: 'TranslationService');

    _channel = _client
        .channel('live-translations:$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_translations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            _handleTranslation(payload.newRecord);
          },
        )
        .subscribe();
  }

  void _handleTranslation(Map<String, dynamic> record) {
    try {
      final translation = LiveTranslation.fromJson(record);

      // Emit caption for UI
      if (_captionsEnabled) {
        _captionController.add(translation);
      }

      // Queue for TTS
      if (_ttsEnabled) {
        final text = translation.getForLanguage(_preferredLanguage);
        if (text.isNotEmpty) {
          _speechQueue.add(text);
          _processQueue();
        }
      }

      dev.log(
        '[Translation] Received: "${translation.originalText.substring(0, translation.originalText.length.clamp(0, 50))}..." → ${translation.translations.keys.join(', ')}',
        name: 'TranslationService',
      );
    } catch (e) {
      dev.log('[Translation] Parse error: $e', name: 'TranslationService');
    }
  }

  Future<void> _processQueue() async {
    if (_isSpeaking || _speechQueue.isEmpty || !_ttsEnabled) return;

    _isSpeaking = true;
    final text = _speechQueue.removeFirst();

    // Set TTS language
    final ttsLang = _ttsLangMap[_preferredLanguage] ?? 'en-IN';
    await _tts.setLanguage(ttsLang);

    _ttsStateController.add(true);
    await _tts.speak(text);
  }

  /// Update preferred language
  void setLanguage(String langCode) {
    _preferredLanguage = langCode;
    dev.log('[Translation] Language set to: $langCode',
        name: 'TranslationService');
  }

  /// Toggle TTS on/off
  void toggleTts() {
    _ttsEnabled = !_ttsEnabled;
    if (!_ttsEnabled) {
      _tts.stop();
      _speechQueue.clear();
      _isSpeaking = false;
    }
    _ttsStateController.add(_ttsEnabled);
  }

  /// Toggle captions on/off
  void toggleCaptions() {
    _captionsEnabled = !_captionsEnabled;
  }

  /// Stop everything and unsubscribe
  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
    _tts.stop();
    _speechQueue.clear();
    _isSpeaking = false;
  }

  void dispose() {
    unsubscribe();
    _captionController.close();
    _ttsStateController.close();
    _tts.stop();
  }
}
