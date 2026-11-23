import 'package:flutter/material.dart';

/// Bingkai oval panduan wajah yang dipakai pendaftaran maupun presensi.
///
/// Area di luar oval digelapkan, area di dalam oval dibiarkan transparan agar
/// hasil kamera tetap terlihat jelas.
class FaceOvalGuidePainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double centerOffsetY;

  const FaceOvalGuidePainter({
    required this.borderColor,
    required this.borderWidth,
    this.centerOffsetY = -24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const ovalWidth = 235.0;
    const ovalHeight = 300.0;
    final center = Offset(size.width / 2, size.height / 2 + centerOffsetY);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );
    final ovalRRect =
        RRect.fromRectAndRadius(ovalRect, const Radius.circular(120));

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final cutOutPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(ovalRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(cutOutPath, dimPaint);

    final strokePaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(ovalRRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant FaceOvalGuidePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.centerOffsetY != centerOffsetY;
  }
}
