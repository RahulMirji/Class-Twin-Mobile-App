import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for sending engagement snapshots to the backend
class EngagementRepository {
  final SupabaseClient _client;

  EngagementRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Send a camera snapshot to the analyze-engagement Edge Function
  Future<EngagementResult> analyzeSnapshot({
    required String sessionId,
    required String studentId,
    required String imageBase64,
    required int roundNumber,
    Map<String, dynamic>? appMetrics,
  }) async {
    log('EngagementRepo: Sending snapshot & telemetry for fusion...');

    final response = await _client.functions.invoke(
      'analyze-engagement',
      body: {
        'sessionId': sessionId,
        'studentId': studentId,
        'imageBase64': imageBase64,
        'roundNumber': roundNumber,
        'appMetrics': appMetrics ?? {},
      },
    );

    if (response.status != 200) {
      final errorMsg = response.data is Map
          ? response.data['error']?.toString() ?? 'Unknown'
          : 'Status ${response.status}';
      throw Exception('Engagement analysis failed: $errorMsg');
    }

    final data = response.data as Map<String, dynamic>;
    log('EngagementRepo: Fusion complete! Comprehension: ${data['comprehension']}');

    return EngagementResult(
      metrics: data['metrics'] as Map<String, dynamic>? ?? {},
      comprehension: (data['comprehension'] as num?)?.toInt() ?? 50,
    );
  }
}

class EngagementResult {
  final Map<String, dynamic> metrics;
  final int comprehension;

  const EngagementResult({
    required this.metrics,
    required this.comprehension,
  });
}
