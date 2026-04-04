import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/stream_service.dart';
import '../../data/stream_repository.dart';

// ─── Repository Provider ──────────────────────────────────────
final streamRepositoryProvider = Provider<StreamRepository>((ref) {
  return StreamRepository();
});

// ─── Stream Service Provider (lazy — only for remote) ─────────
final streamServiceProvider = Provider<StreamService>((ref) {
  final service = StreamService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Stream Connection State ──────────────────────────────────
final streamConnectionStateProvider =
    StreamProvider<StreamConnectionState>((ref) {
  final service = ref.watch(streamServiceProvider);
  return service.connectionState;
});

// ─── Connect to Stream ───────────────────────────────────────
final connectToStreamProvider =
    FutureProvider.family<void, ({String sessionId, String studentId})>(
        (ref, params) async {
  final repo = ref.read(streamRepositoryProvider);
  final service = ref.read(streamServiceProvider);

  // Fetch LiveKit token
  final tokenResponse = await repo.fetchToken(
    sessionId: params.sessionId,
    studentId: params.studentId,
  );

  // Connect to LiveKit room
  await service.connect(
    wsUrl: tokenResponse.wsUrl,
    token: tokenResponse.token,
  );
});
