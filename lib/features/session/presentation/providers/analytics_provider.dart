import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics_service.dart';

// ─── Analytics Service Provider ───────────────────────────────
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
