import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// [data] as a QR code: dark modules on white with a quiet zone, the way
/// scanners read best, in light and dark mode alike.
class QrCodeView extends StatelessWidget {
  final String data;
  final double size;
  final String semanticLabel;

  const QrCodeView({
    super.key,
    required this.data,
    required this.semanticLabel,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final image = QrImage(
      QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: CustomPaint(size: Size.square(size), painter: _QrPainter(image)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final QrImage image;

  _QrPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final cell = size.width / count;
    final paint = Paint()..color = const Color(0xFF111111);
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!image.isDark(row, col)) continue;
        // A hair of overlap so neighbouring modules don't show seams.
        canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}
