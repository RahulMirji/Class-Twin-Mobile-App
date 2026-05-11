import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../domain/models/peer_recommendation.dart';

/// Provider to fetch a peer recommendation for the current session.
/// Returns null if the current student is not struggling or no suitable peer is found.
final peerRecommendationProvider = FutureProvider.family<PeerRecommendation?, String>((ref, sessionId) async {
  try {
    final authState = ref.watch(authStateProvider);
    final currentEmail = authState.value?.email;

    if (currentEmail == null) {
      return null;
    }

    final supabase = Supabase.instance.client;

    // 1. Fetch current student's session stats
    final currentUserRes = await supabase
        .from('session_students')
        .select()
        .eq('session_id', sessionId)
        .eq('email', currentEmail)
        .maybeSingle();

    if (currentUserRes == null) {
      dev.log('[PeerRecommendation] Current user not found in session_students', name: 'PeerRecommendation');
      return null;
    }

    final currentComprehension = currentUserRes['comprehension'] as int? ?? 0;
    final currentRisk = currentUserRes['risk'] as String? ?? 'ON_TRACK';
    final currentLanguage = currentUserRes['language'] as String? ?? 'English';

    // 2. Check if current student qualifies as "struggling"
    // Criteria: Risk is AT_RISK or HIGH_RISK, OR comprehension is below 60
    final isStruggling = currentRisk != 'ON_TRACK' || currentComprehension < 60;

    if (!isStruggling) {
      dev.log('[PeerRecommendation] Student is doing well, no peer recommended.', name: 'PeerRecommendation');
      return null;
    }

    // 3. Find a high-performing peer in the same session with the same language
    // Criteria: Risk is ON_TRACK and comprehension > 80
    final peerRes = await supabase
        .from('session_students')
        .select()
        .eq('session_id', sessionId)
        .eq('language', currentLanguage)
        .eq('risk', 'ON_TRACK')
        .gt('comprehension', 80)
        .neq('email', currentEmail) // Exclude self just in case
        .order('comprehension', ascending: false)
        .limit(1)
        .maybeSingle();

    if (peerRes == null) {
      dev.log('[PeerRecommendation] No suitable peer found matching criteria.', name: 'PeerRecommendation');
      return null;
    }
    dev.log('[PeerRecommendation] Found peer: ${peerRes["student_name"]}', name: 'PeerRecommendation');
    return PeerRecommendation.fromJson(peerRes);

  } catch (e, stack) {
    dev.log('[PeerRecommendation] Error: $e', name: 'PeerRecommendation', error: e, stackTrace: stack);
    return null;
  }
});
