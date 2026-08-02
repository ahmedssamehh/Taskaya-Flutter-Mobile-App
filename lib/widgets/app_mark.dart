import 'package:flutter/material.dart';

/// The Taskaya mark: a rounded task card with a checkmark breaking out
/// through the top-right corner. Always drawn with currentColor so it
/// inverts for free between light and dark themes.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final strokeWidth = size <= 24 ? 4.5 : 3.5;
    return CustomPaint(
      size: Size(size, size),
      painter: _AppMarkPainter(
        color: color ?? IconTheme.of(context).color ?? Colors.black,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _AppMarkPainter extends CustomPainter {
  _AppMarkPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(5 * scale, 13 * scale, 30 * scale, 30 * scale);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(8 * scale));
    canvas.drawRRect(rrect, paint);

    final path = Path()
      ..moveTo(13 * scale, 29 * scale)
      ..lineTo(21 * scale, 36 * scale)
      ..lineTo(43 * scale, 7 * scale);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AppMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
