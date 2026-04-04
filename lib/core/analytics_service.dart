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
  responseSubmitted,
  responseUndone,
}

class AnalyticsService {
  void track(AnalyticsEvent event, [Map<String, dynamic>? properties]) {
    // TODO: Integrate with your analytics backend (Mixpanel, Amplitude, etc.)
    // For now, just log
    // print('Analytics: ${event.name} ${properties ?? ''}');
  }
}
