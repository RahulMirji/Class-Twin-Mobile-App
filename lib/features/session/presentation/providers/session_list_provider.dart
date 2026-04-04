import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:class_twin/features/session/domain/models/session.dart';

/// Active sessions — fetches initially then listens for Realtime changes
final activeSessionsProvider = StreamProvider<List<Session>>((ref) {
  final controller = StreamController<List<Session>>();
  
  // 1. Initial fetch via REST (fast, reliable)
  _fetchSessions('active').then((sessions) {
    if (!controller.isClosed) controller.add(sessions);
  }).catchError((e) {
    if (!controller.isClosed) controller.addError(e);
  });

  // 2. Subscribe to Realtime changes (updates only)
  final channel = Supabase.instance.client
      .channel('active-sessions')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sessions',
        callback: (payload) async {
          // Re-fetch the full list on any change
          try {
            final sessions = await _fetchSessions('active');
            if (!controller.isClosed) controller.add(sessions);
          } catch (_) {}
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Upcoming sessions — same pattern
final upcomingSessionsProvider = StreamProvider<List<Session>>((ref) {
  final controller = StreamController<List<Session>>();
  
  // 1. Initial fetch via REST
  _fetchSessions('waiting').then((sessions) {
    if (!controller.isClosed) controller.add(sessions);
  }).catchError((e) {
    if (!controller.isClosed) controller.addError(e);
  });

  // 2. Subscribe to Realtime changes
  final channel = Supabase.instance.client
      .channel('upcoming-sessions')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sessions',
        callback: (payload) async {
          try {
            final sessions = await _fetchSessions('waiting');
            if (!controller.isClosed) controller.add(sessions);
          } catch (_) {}
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Fetch sessions by status via REST API (reliable, no Realtime dependency)
Future<List<Session>> _fetchSessions(String status) async {
  final data = await Supabase.instance.client
      .from('sessions')
      .select()
      .eq('status', status)
      .order('created_at');
  return (data as List).map((json) => Session.fromJson(json)).toList();
}
