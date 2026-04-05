import 'dart:async';
import 'package:livekit_client/livekit_client.dart';

/// StreamService — manages LiveKit room connection
/// Now supports two-way audio (student can unmute)
class StreamService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  final _cameraTrackController =
      StreamController<VideoTrack?>.broadcast();
  final _screenTrackController =
      StreamController<VideoTrack?>.broadcast();
  final _connectionStateController =
      StreamController<StreamConnectionState>.broadcast();
  final _micStateController = StreamController<bool>.broadcast();

  Stream<VideoTrack?> get cameraTrack => _cameraTrackController.stream;
  Stream<VideoTrack?> get screenTrack => _screenTrackController.stream;
  Stream<StreamConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<bool> get micState => _micStateController.stream;

  VideoTrack? get currentCameraTrack => _currentCameraTrack;
  VideoTrack? get currentScreenTrack => _currentScreenTrack;
  bool get isMicEnabled => _isMicEnabled;

  VideoTrack? _currentCameraTrack;
  VideoTrack? _currentScreenTrack;
  bool _isMicEnabled = false;

  bool get isConnected =>
      _room?.connectionState == ConnectionState.connected;

  Future<void> connect({
    required String wsUrl,
    required String token,
  }) async {
    _connectionStateController.add(StreamConnectionState.connecting);

    _room = Room();

    // Create event listener
    _listener = _room!.createListener();

    // Listen for track subscriptions
    _listener!
      ..on<TrackSubscribedEvent>((event) {
        final track = event.track;
        if (track is VideoTrack) {
          if (event.publication.source == TrackSource.screenShareVideo) {
            _currentScreenTrack = track;
            _screenTrackController.add(track);
          } else {
            _currentCameraTrack = track;
            _cameraTrackController.add(track);
          }
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (event.publication.source == TrackSource.screenShareVideo) {
          _currentScreenTrack = null;
          _screenTrackController.add(null);
        } else if (event.track is VideoTrack) {
          _currentCameraTrack = null;
          _cameraTrackController.add(null);
        }
      })
      ..on<RoomDisconnectedEvent>((event) {
        _connectionStateController.add(StreamConnectionState.disconnected);
      });

    try {
      await _room!.connect(wsUrl, token);
      
      // Ensure mic starts disabled by default
      await _room!.localParticipant?.setMicrophoneEnabled(false);
      _isMicEnabled = false;
      _micStateController.add(false);
      
      _connectionStateController.add(StreamConnectionState.connected);
    } catch (e) {
      _connectionStateController.add(StreamConnectionState.error);
      rethrow;
    }
  }

  Future<void> toggleMicrophone() async {
    if (_room == null) return;
    
    _isMicEnabled = !_isMicEnabled;
    await _room!.localParticipant?.setMicrophoneEnabled(_isMicEnabled);
    _micStateController.add(_isMicEnabled);
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _currentCameraTrack = null;
    _currentScreenTrack = null;
    _cameraTrackController.add(null);
    _screenTrackController.add(null);
    _isMicEnabled = false;
    _micStateController.add(false);
    _listener?.dispose();
    _listener = null;
    _room = null;
    _connectionStateController.add(StreamConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _cameraTrackController.close();
    _screenTrackController.close();
    _connectionStateController.close();
    _micStateController.close();
  }
}

enum StreamConnectionState { disconnected, connecting, connected, error }
