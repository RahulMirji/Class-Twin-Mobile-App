import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Model for a single live translation event
class LiveTranslation {
  final String originalText;
  final String sourceLang;
  final Map<String, String> translations;
  final Map<String, String> audio; // base64 MP3 audio per language
  final DateTime createdAt;

  LiveTranslation({
    required this.originalText,
    required this.sourceLang,
    required this.translations,
    this.audio = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get translated text for a specific language, falling back to original
  String getForLanguage(String langCode) {
    return translations[langCode] ?? originalText;
  }

  /// Check if neural audio is available for a language
  bool hasAudioFor(String langCode) => audio.containsKey(langCode);

  factory LiveTranslation.fromJson(Map<String, dynamic> json) {
    final rawTranslations = json['translations'];
    final Map<String, String> parsed = {};
    if (rawTranslations is Map) {
      rawTranslations.forEach((key, value) {
        parsed[key.toString()] = value.toString();
      });
    }

    // Parse audio map (base64 MP3 per language)
    final rawAudio = json['audio'];
    final Map<String, String> audioMap = {};
    if (rawAudio is Map) {
      rawAudio.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          audioMap[key.toString()] = value.toString();
        }
      });
    }

    return LiveTranslation(
      originalText: json['original_text'] as String? ?? '',
      sourceLang: json['source_lang'] as String? ?? 'en',
      translations: parsed,
      audio: audioMap,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// TTS language code mapping (BCP 47 format) — fallback device TTS
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

/// Audio item in the playback queue
class _AudioItem {
  final String text;
  final String? base64Audio; // null = use device TTS

  _AudioItem({required this.text, this.base64Audio});
}

/// TranslationService — listens to live_translations via Supabase Realtime
/// and plays them using Cloud Neural TTS (with device TTS fallback).
class TranslationService {
  final SupabaseClient _client;
  final FlutterTts _tts;
  final AudioPlayer _audioPlayer;

  RealtimeChannel? _channel;
  String _preferredLanguage = 'en';
  bool _ttsEnabled = true;
  bool _captionsEnabled = true;
  bool _isSpeaking = false;
  final Queue<_AudioItem> _speechQueue = Queue<_AudioItem>();

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
        _tts = FlutterTts(),
        _audioPlayer = AudioPlayer() {
    _initTts();
    _initAudioPlayer();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.65);
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

  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      _ttsStateController.add(false);
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

      // Queue for audio playback
      if (_ttsEnabled) {
        final text = translation.getForLanguage(_preferredLanguage);
        if (text.isNotEmpty) {
          // Prefer server-generated neural audio if available
          final audioBase64 = translation.hasAudioFor(_preferredLanguage)
              ? translation.audio[_preferredLanguage]
              : null;

          _speechQueue.add(_AudioItem(text: text, base64Audio: audioBase64));
          dev.log(
            '[Translation] Queued: ${audioBase64 != null ? "🔊 Neural audio" : "📱 Device TTS"} for $_preferredLanguage',
            name: 'TranslationService',
          );
          _processQueue();
        }
      }

      dev.log(
        '[Translation] Received: "${translation.originalText.substring(0, translation.originalText.length.clamp(0, 50))}..." → ${translation.translations.keys.join(', ')} | audio: ${translation.audio.keys.join(', ')}',
        name: 'TranslationService',
      );
    } catch (e) {
      dev.log('[Translation] Parse error: $e', name: 'TranslationService');
    }
  }

  Future<void> _processQueue() async {
    if (_isSpeaking || _speechQueue.isEmpty || !_ttsEnabled) return;

    _isSpeaking = true;
    final item = _speechQueue.removeFirst();
    _ttsStateController.add(true);

    if (item.base64Audio != null) {
      // Play neural audio from server (natural-sounding)
      await _playBase64Audio(item.base64Audio!);
    } else {
      // Fallback to device TTS
      final ttsLang = _ttsLangMap[_preferredLanguage] ?? 'en-IN';
      await _tts.setLanguage(ttsLang);
      await _tts.speak(item.text);
    }
  }

  /// Play base64-encoded MP3 audio
  Future<void> _playBase64Audio(String base64Data) async {
    try {
      final bytes = base64Decode(base64Data);
      
      // Write to temp file for audioplayers
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/neural_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await tempFile.writeAsBytes(bytes);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      
      // Clean up temp file after a delay
      Future.delayed(const Duration(seconds: 30), () {
        tempFile.delete().catchError((_) => tempFile);
      });
    } catch (e) {
      dev.log('[TTS] Neural audio playback failed, falling back to device TTS: $e',
          name: 'TranslationService');
      // Fallback to device TTS
      _isSpeaking = false;
      final ttsLang = _ttsLangMap[_preferredLanguage] ?? 'en-IN';
      await _tts.setLanguage(ttsLang);
      await _tts.speak(_speechQueue.isNotEmpty ? _speechQueue.first.text : '');
    }
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
      _audioPlayer.stop();
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
    _audioPlayer.stop();
    _speechQueue.clear();
    _isSpeaking = false;
  }

  void dispose() {
    unsubscribe();
    _captionController.close();
    _ttsStateController.close();
    _tts.stop();
    _audioPlayer.dispose();
  }
}
