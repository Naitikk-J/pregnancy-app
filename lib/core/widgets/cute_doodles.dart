import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Handcrafted cute vector doodles and decorators for maternal & baby wellness.
class CuteSparkle extends StatelessWidget {
  const CuteSparkle({
    this.size = 20,
    this.color = const Color(0xFFFBBF24),
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, w, cy);
    path.quadraticBezierTo(cx, cy, cx, h);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Center shine dot
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.12, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Cute chubby doodle heart with a shine reflection.
class CuteHeart extends StatelessWidget {
  const CuteHeart({
    this.size = 22,
    this.color = const Color(0xFFFB7185),
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CuteHeartPainter(color),
    );
  }
}

class _CuteHeartPainter extends CustomPainter {
  _CuteHeartPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.1, h * 0.55, 0, h * 0.28, w * 0.25, h * 0.12);
    path.cubicTo(w * 0.42, h * 0.02, w * 0.5, h * 0.2, w * 0.5, h * 0.2);
    path.cubicTo(w * 0.5, h * 0.2, w * 0.58, h * 0.02, w * 0.75, h * 0.12);
    path.cubicTo(w, h * 0.28, w * 0.9, h * 0.55, w * 0.5, h * 0.85);
    path.close();

    canvas.drawPath(path, paint);

    // Shine reflection
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.22, h * 0.2, w * 0.16, h * 0.22),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CuteHeartPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Cute 5-petal flower doodle.
class CuteFlower extends StatelessWidget {
  const CuteFlower({
    this.size = 24,
    this.petalColor = const Color(0xFFFFB6C8),
    this.centerColor = const Color(0xFFFDE047),
    super.key,
  });

  final double size;
  final Color petalColor;
  final Color centerColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CuteFlowerPainter(petalColor, centerColor),
    );
  }
}

class _CuteFlowerPainter extends CustomPainter {
  _CuteFlowerPainter(this.petalColor, this.centerColor);
  final Color petalColor;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final petalPaint = Paint()..color = petalColor;
    final centerPaint = Paint()..color = centerColor;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final petalRadius = size.width * 0.22;
    final distance = size.width * 0.26;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final px = cx + distance * math.cos(angle);
      final py = cy + distance * math.sin(angle);
      canvas.drawCircle(Offset(px, py), petalRadius, petalPaint);
    }

    // Flower center
    canvas.drawCircle(Offset(cx, cy), size.width * 0.2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _CuteFlowerPainter oldDelegate) =>
      oldDelegate.petalColor != petalColor ||
      oldDelegate.centerColor != centerColor;
}

/// Cute fluffy baby cloud doodle.
class CuteCloud extends StatelessWidget {
  const CuteCloud({
    this.size = 32,
    this.color = Colors.white,
    this.opacity = 0.85,
    super.key,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.6),
      painter: _CuteCloudPainter(color.withValues(alpha: opacity)),
    );
  }
}

class _CuteCloudPainter extends CustomPainter {
  _CuteCloudPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.35, w * 0.8, h * 0.55),
        Radius.circular(h * 0.28),
      ),
    );
    canvas.drawPath(path, paint);

    // Upper cloud puffs
    canvas.drawCircle(Offset(w * 0.32, h * 0.45), h * 0.38, paint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.38), h * 0.44, paint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.52), h * 0.32, paint);
  }

  @override
  bool shouldRepaint(covariant _CuteCloudPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Cute baby footprint doodle.
class CuteFootprint extends StatelessWidget {
  const CuteFootprint({
    this.size = 22,
    this.color = const Color(0xFFC48B9F),
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.65, size),
      painter: _CuteFootprintPainter(color),
    );
  }
}

class _CuteFootprintPainter extends CustomPainter {
  _CuteFootprintPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Main sole
    final solePath = Path();
    solePath.moveTo(w * 0.4, h * 0.35);
    solePath.cubicTo(w * 0.05, h * 0.45, w * 0.05, h * 0.75, w * 0.35, h * 0.95);
    solePath.cubicTo(w * 0.75, h * 0.95, w * 0.9, h * 0.65, w * 0.85, h * 0.45);
    solePath.cubicTo(w * 0.8, h * 0.3, w * 0.6, h * 0.28, w * 0.4, h * 0.35);
    solePath.close();
    canvas.drawPath(solePath, paint);

    // 5 Baby Toes
    final toeOffsets = [
      Offset(w * 0.22, h * 0.16),
      Offset(w * 0.40, h * 0.10),
      Offset(w * 0.58, h * 0.12),
      Offset(w * 0.74, h * 0.18),
      Offset(w * 0.88, h * 0.26),
    ];
    final toeRadii = [w * 0.14, w * 0.12, w * 0.10, w * 0.08, w * 0.07];

    for (int i = 0; i < toeOffsets.length; i++) {
      canvas.drawCircle(toeOffsets[i], toeRadii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CuteFootprintPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A cheerful category pill chip decorated with pastel background and doodle.
class CuteCategoryBadge extends StatelessWidget {
  const CuteCategoryBadge({
    required this.title,
    required this.icon,
    this.color = const Color(0xFFC48B9F),
    this.count,
    super.key,
  });

  final String title;
  final Widget icon;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
