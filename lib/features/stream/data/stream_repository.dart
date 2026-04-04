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
    final response = await _client.functions.invoke(
      'livekit-token',
      body: {
        'sessionId': sessionId,
        'studentId': studentId,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to fetch LiveKit token: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    return LiveKitTokenResponse(
      token: data['token'] as String,
      wsUrl: data['wsUrl'] as String,
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
