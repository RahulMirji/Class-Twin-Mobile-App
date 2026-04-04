import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'engagement_repository.dart';

/// EngagementService — silently captures front-camera snapshots
/// and sends them for AI engagement analysis
/// EngagementService — silently captures front-camera snapshots
/// and sends them for AI engagement analysis
class EngagementService with WidgetsBindingObserver {
  CameraController? _controller;
  Timer? _captureTimer;
  bool _isRunning = false;
  bool _isCapturing = false;
  bool _isTabActive = true;

  final EngagementRepository _repository;
  String? _sessionId;
  String? _studentId;
  int _roundNumber = 0;
  Map<String, dynamic> Function()? _getAppMetrics;

  /// How often to capture (in seconds) - dropped to 10s for high-frequency telemetry
  static const int captureIntervalSeconds = 10;

  EngagementService({EngagementRepository? repository})
      : _repository = repository ?? EngagementRepository() {
    WidgetsBinding.instance.addObserver(this);
  }

  final ValueNotifier<CameraController?> cameraControllerNotifier = ValueNotifier(null);
  
  bool get isRunning => _isRunning;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isTabActive = true;
    } else {
      _isTabActive = false; // Backgrounded, inactive, paused
    }
  }

  /// Start the engagement tracking loop
  Future<void> start({
    required String sessionId,
    required String studentId,
    int roundNumber = 0,
    Map<String, dynamic> Function()? getAppMetrics,
  }) async {
    if (_isRunning) return;

    _sessionId = sessionId;
    _studentId = studentId;
    _roundNumber = roundNumber;
    _getAppMetrics = getAppMetrics;

    log('EngagementService: Starting camera-based tracking...');

    try {
      // Get the front camera
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize with low resolution to save bandwidth
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low, // 352x288 — tiny, ~20-40KB JPEG
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      cameraControllerNotifier.value = _controller;
      _isRunning = true;

      // Start the periodic capture loop
      _captureTimer = Timer.periodic(
        const Duration(seconds: captureIntervalSeconds),
        (_) => _captureAndAnalyze(),
      );

      // Do one immediate capture after a short delay
      Future.delayed(const Duration(seconds: 3), () => _captureAndAnalyze());

      log('EngagementService: Camera initialized, capturing every ${captureIntervalSeconds}s');
    } catch (e) {
      log('EngagementService: Failed to start camera: $e');
      // Don't throw — engagement tracking is non-critical
    }
  }

  /// Update the current round number
  void updateRound(int roundNumber) {
    _roundNumber = roundNumber;
  }

  /// Capture a frame and send for analysis
  Future<void> _captureAndAnalyze() async {
    if (!_isRunning || _isCapturing || _controller == null) return;
    if (!_controller!.value.isInitialized) return;

    _isCapturing = true;

    try {
      // Take a picture
      final XFile image = await _controller!.takePicture();
      final Uint8List bytes = await image.readAsBytes();

      // Convert to base64
      final String base64Image = base64Encode(bytes);

      // Collect telemetry
      final appMetrics = _getAppMetrics != null ? _getAppMetrics!() : <String, dynamic>{};
      appMetrics['tab_active'] = _isTabActive;

      log('EngagementService: Captured frame (${bytes.length} bytes), sending for analysis...');

      // Send to Edge Function (fire and forget — don't block)
      _repository.analyzeSnapshot(
        sessionId: _sessionId!,
        studentId: _studentId!,
        imageBase64: base64Image,
        roundNumber: _roundNumber,
        appMetrics: appMetrics,
      ).then((result) {
        log('EngagementService: Student analysis complete');
      }).catchError((e) {
        log('EngagementService: Analysis error (non-fatal): $e');
      });
    } catch (e) {
      log('EngagementService: Capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  /// Stop tracking and release camera
  Future<void> stop() async {
    log('EngagementService: Stopping...');
    _isRunning = false;
    _captureTimer?.cancel();
    _captureTimer = null;

    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    cameraControllerNotifier.value = null;
  }

  /// Dispose everything
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await stop();
  }
}
