import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/translation_service.dart';

/// Singleton provider for the TranslationService
final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  ref.onDispose(() => service.dispose());
  return service;
});
