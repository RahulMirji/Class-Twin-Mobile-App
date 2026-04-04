import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../session/presentation/providers/session_provider.dart';

class ConfidenceSlider extends ConsumerStatefulWidget {
  const ConfidenceSlider({super.key});

  @override
  ConsumerState<ConfidenceSlider> createState() => _ConfidenceSliderState();
}

class _ConfidenceSliderState extends ConsumerState<ConfidenceSlider> {
  // 0 = Lost (Red), 100 = Got it (Green). Starts neutral (50)
  double _value = 50;
  Timer? _debounce;
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onDragUpdate(double delta, double maxWidth) {
    final deltaValue = (delta / maxWidth) * 100;
    setState(() {
      _value = (_value + deltaValue).clamp(0, 100);
    });
    
    // Debounce the backend update
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final student = ref.read(currentStudentProvider);
      if (student != null) {
        ref.read(sessionRepositoryProvider).updateStudentConfidence(student.id, _value.round());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.redAccent, Colors.greenAccent, _value / 100)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("I'm lost", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Text("I got it!", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            
            return GestureDetector(
              onHorizontalDragUpdate: (details) => _onDragUpdate(details.delta.dx, maxWidth),
              child: Container(
                height: 48, // Fatter, more grab-able track
                width: maxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Colors.orangeAccent, Colors.greenAccent],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Moving Thumb
                    Positioned(
                      left: (maxWidth - 48) * (_value / 100),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: color, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _value > 70 ? Icons.rocket_launch :
                            _value < 30 ? Icons.warning_rounded :
                            Icons.sentiment_satisfied_rounded,
                            size: 24,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ],
    );
  }
}
