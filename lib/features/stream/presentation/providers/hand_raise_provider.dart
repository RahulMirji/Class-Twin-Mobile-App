import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/hand_raise_repository.dart';
import '../../domain/models/hand_raise.dart';

// ─── Repository Provider ──────────────────────────────────────
final handRaiseRepositoryProvider = Provider<HandRaiseRepository>((ref) {
  return HandRaiseRepository();
});

// ─── Hand Raise State ─────────────────────────────────────────
final handRaiseProvider =
    StateNotifierProvider<HandRaiseNotifier, HandRaiseState>((ref) {
  return HandRaiseNotifier(ref);
});

class HandRaiseState {
  final bool isRaised;
  final HandRaise? currentRaise;
  final bool isLoading;

  const HandRaiseState({
    this.isRaised = false,
    this.currentRaise,
    this.isLoading = false,
  });

  HandRaiseState copyWith({
    bool? isRaised,
    HandRaise? currentRaise,
    bool? isLoading,
  }) {
    return HandRaiseState(
      isRaised: isRaised ?? this.isRaised,
      currentRaise: currentRaise ?? this.currentRaise,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HandRaiseNotifier extends StateNotifier<HandRaiseState> {
  final Ref _ref;

  HandRaiseNotifier(this._ref) : super(const HandRaiseState());

  HandRaiseRepository get _repo => _ref.read(handRaiseRepositoryProvider);

  /// Raise hand for current round
  Future<void> raiseHand({
    required String sessionId,
    required String studentId,
    required int roundNumber,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final raise = await _repo.raiseHand(
        sessionId: sessionId,
        studentId: studentId,
        roundNumber: roundNumber,
      );

      state = HandRaiseState(
        isRaised: true,
        currentRaise: raise,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Lower hand
  Future<void> lowerHand() async {
    final raise = state.currentRaise;
    if (raise == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _repo.lowerHand(raise.id);
      state = const HandRaiseState(isRaised: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Auto-lower when next question arrives (per PRD — resets per round)
  void autoLower() {
    state = const HandRaiseState(isRaised: false);
  }
}
