import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    const double scanAreaSize = 260.0; // Consistent size for both

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View (Fills entire background)
          Positioned.fill(
            child: MobileScanner(
              onDetect: (capture) {
                if (_isScanned) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  _isScanned = true;
                  final String code = barcodes.first.rawValue!;
                  Navigator.of(context).pop(code);
                }
              },
            ),
          ),
          
          // 2. Dark Overlay with "Hole"
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayShape(scanAreaSize: scanAreaSize),
            ),
          ),

          // 3. UI Layer (Centered Border and Text)
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Text above the box
                Text(
                  'Scan the QR Code to Join',
                  style: AppTheme.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
                
                const SizedBox(height: 32),
                
                // The White Border Frame
                Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9), 
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  // Animated scanning line inside? (optional but premium)
                  child: Stack(
                    children: [
                       _ScanningLine(width: scanAreaSize),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Helper Instruction
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    'Align the code within the frame',
                    style: AppTheme.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                const Spacer(flex: 3),
              ],
            ),
          ),
          
          // 4. Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsBold.x, color: Colors.white, size: 24),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningLine extends StatelessWidget {
  final double width;
  const _ScanningLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container()
      .animate(onPlay: (controller) => controller.repeat())
      .custom(
        duration: 2.seconds,
        builder: (context, value, child) {
          return Positioned(
            top: value * (width - 4),
            left: 10,
            right: 10,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }
}

class _ScannerOverlayShape extends CustomPainter {
  final double scanAreaSize;
  _ScannerOverlayShape({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // The whole screen
    final screenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // We need to match the vertical positioning of the Column's centered box
    // Since we used Spacer(flex: 2) ... box ... Spacer(flex: 3)
    // The center of the box is at (2 / 5) + (boxSize / 2) relative? No.
    // Better: Fix the box to be exactly centered in the Painter too.
    
    // Actually, in the Column implementation above, the box isn't perfectly centered vertically either.
    // Let's change the UI to use a Stack with a truly centered box for both.
    
    final center = Offset(size.width / 2, size.height / 2);
    // Aligning with the "Manual" vertical offset that feels good (slightly above center usually)
    // But for simplicity and correctness, let's stick to true center for both now.
    
    final boxRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );
    
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        boxRect,
        const Radius.circular(32),
      ));

    // Subtract cutout from screen
    final overlayPath = Path.combine(PathOperation.difference, screenPath, cutoutPath);
    
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

