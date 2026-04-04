/// ClassTwin constants — replace placeholders with your actual credentials
class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // LiveKit
  static const String livekitWsUrl = 'YOUR_LIVEKIT_WS_URL';
  static const String livekitTokenEndpoint =
      '\$supabaseUrl/functions/v1/livekit-token';

  // Realtime channel prefix
  static const String sessionChannelPrefix = 'session:';

  // Chat
  static const Duration chatRateLimitDuration = Duration(seconds: 3);
  static const int maxChatMessageLength = 500;

  // Stream
  static const Duration streamReconnectDelay = Duration(seconds: 2);
  static const int maxStreamReconnectAttempts = 5;

  // Sentry
  static const String sentryDsn = 'YOUR_SENTRY_DSN';
}
