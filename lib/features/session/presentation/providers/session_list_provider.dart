import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session, SessionStatus;
import 'package:class_twin/features/session/domain/models/session.dart';

final activeSessionsProvider = StreamProvider<List<Session>>((ref) {
  return Supabase.instance.client
      .from('sessions')
      .stream(primaryKey: ['id'])
      .eq('status', 'active')
      .order('created_at')
      .map((data) => data.map((json) => Session.fromJson(json)).toList());
});

final upcomingSessionsProvider = StreamProvider<List<Session>>((ref) {
  return Supabase.instance.client
      .from('sessions')
      .stream(primaryKey: ['id'])
      .eq('status', 'waiting')
      .order('created_at')
      .map((data) => data.map((json) => Session.fromJson(json)).toList());
});
