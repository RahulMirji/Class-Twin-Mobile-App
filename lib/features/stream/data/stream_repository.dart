import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stream repository — handles LiveKit token fetching
class StreamRepository {
  final SupabaseClient _client;

  StreamRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch a LiveKit subscriber token from the Supabase Edge Function
  Future<LiveKitTokenResponse> fetchToken({
    required String sessionId,
    required String studentId,
  }) async {
    log('StreamRepo: Fetching token for session=$sessionId, student=$studentId');
    
    final response = await _client.functions.invoke(
      'livekit-token',
      body: {
        'sessionId': sessionId,
        'studentId': studentId,
      },
    );

    log('StreamRepo: Response status=${response.status}, data=${response.data}');

    if (response.status != 200) {
      final errorMsg = response.data is Map 
          ? response.data['error']?.toString() ?? 'Unknown error'
          : 'Status ${response.status}';
      throw Exception('Failed to fetch LiveKit token: $errorMsg');
    }

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from livekit-token function');
    }

    final token = data['token'] as String?;
    // Support both 'wsUrl' and 'url' field names
    final wsUrl = (data['wsUrl'] ?? data['url']) as String?;
    
    if (token == null) {
      throw Exception(
        'Missing token in response. '
        'Keys: ${data.keys.toList()}. '
        'Error: ${data['error'] ?? 'none'}'
      );
    }

    // Fallback to known LiveKit URL if not in response
    final resolvedWsUrl = wsUrl ?? 'wss://class-twin-gpmml780.livekit.cloud';

    return LiveKitTokenResponse(
      token: token,
      wsUrl: resolvedWsUrl,
    );
  }
}

class LiveKitTokenResponse {
  final String token;
  final String wsUrl;

  const LiveKitTokenResponse({
    required this.token,
    required this.wsUrl,
  });
}
