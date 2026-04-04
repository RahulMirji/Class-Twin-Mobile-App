import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

class SystemStatus {
  final int batteryLevel;
  final bool isLowBattery;
  final bool isPoorConnection;
  final double? latencyMs;

  SystemStatus({
    required this.batteryLevel,
    required this.isLowBattery,
    required this.isPoorConnection,
    this.latencyMs,
  });

  SystemStatus copyWith({
    int? batteryLevel,
    bool? isLowBattery,
    bool? isPoorConnection,
    double? latencyMs,
  }) {
    return SystemStatus(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isLowBattery: isLowBattery ?? this.isLowBattery,
      isPoorConnection: isPoorConnection ?? this.isPoorConnection,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}

class SystemMonitorNotifier extends StateNotifier<SystemStatus> {
  final Battery _battery = Battery();
  Timer? _timer;

  SystemMonitorNotifier()
      : super(SystemStatus(
          batteryLevel: 100,
          isLowBattery: false,
          isPoorConnection: false,
        )) {
    _init();
  }

  void _init() {
    // Monitor battery
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkStatus());
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final level = await _battery.batteryLevel;
    state = state.copyWith(
      batteryLevel: level,
      isLowBattery: level < 20,
    );
  }

  void updateLatency(double latency) {
    state = state.copyWith(
      latencyMs: latency,
      isPoorConnection: latency > 500,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final systemMonitorProvider =
    StateNotifierProvider<SystemMonitorNotifier, SystemStatus>((ref) {
  return SystemMonitorNotifier();
});
