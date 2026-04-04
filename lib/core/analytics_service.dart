import 'package:flutter/foundation.dart';

/// Analytics events from PRD Section 12
enum AnalyticsEvent {
  // Stream events
  streamConnected,
  streamDisconnected,
  streamDropped,
  streamQualityDegraded,
  streamLayoutChanged,

  // Interaction events
  chatMessageSent,
  chatMessageSentAnonymous,
  handRaised,
  handLowered,
  handAutoLowered,

  // Mode events
  joinedAsRemote,
  joinedAsInRoom,
  batteryWarningShown,

  // Session events
  sessionJoined,
  sessionLeft,
  joinFail,
  streamReconnect,
  responseSubmitted,
  responseUndone,
}

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  void track(AnalyticsEvent event, [Map<String, dynamic>? properties]) {
    // TODO: Integrate with your analytics backend (Mixpanel, Amplitude, etc.)
    debugPrint('Analytics: ${event.name} ${properties ?? ''}');
  }
}
