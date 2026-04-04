import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/engagement_service.dart';
import '../../data/engagement_repository.dart';

/// Engagement repository provider
final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return EngagementRepository();
});

/// Engagement service provider — manages the camera lifecycle
final engagementServiceProvider = Provider<EngagementService>((ref) {
  final repo = ref.read(engagementRepositoryProvider);
  final service = EngagementService(repository: repo);
  ref.onDispose(() => service.dispose());
  return service;
});
