/// Class Twin constants — replace placeholders with your actual credentials
class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'https://woulwfbaejlwlgfbpnqu.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvdWx3ZmJhZWpsd2xnZmJwbnF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyOTI1NzAsImV4cCI6MjA5MDg2ODU3MH0.ERr53qwAFD5Dl48plRAMOQBcrVxai27D2FuwEI47YNA';

  // Google OAuth
  static const String googleWebClientId = '1012466165958-0qg202r92evkasgdcldgr4d8tail3jp8.apps.googleusercontent.com';

  // LiveKit
  static const String livekitWsUrl = 'wss://class-twin-gpmml780.livekit.cloud';
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
