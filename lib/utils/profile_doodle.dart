import 'package:flutter/material.dart';

class ProfileDoodleIcon extends StatelessWidget {
  
  final double size;

  /// true - filled
  final bool filled;

  const ProfileDoodleIcon({
    super.key,
    this.size   = 24,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!filled) {

      return SizedBox(
        width:  size,
        height: size,
        child: CustomPaint(painter: _PersonPainter(size: size, filled: false)),
      );
    }

   
    return CircleAvatar(
      radius:          size / 2,
      backgroundColor: Colors.teal,
      child: SizedBox(
        width:  size * 0.58,   
        height: size * 0.58,
        child: CustomPaint(
          painter: _PersonPainter(size: size * 0.58, filled: false, color: Colors.white),
        ),
      ),
    );
  }
}

class _PersonPainter extends CustomPainter {
  final double size;
  final bool   filled;
  final Color  color;
  const _PersonPainter({required this.size, required this.filled, this.color = const Color(0xFF2E7D6E)});

  @override
  void paint(Canvas canvas, Size s) {
    final cx   = size / 2;
    final cy   = size / 2;
    final pad  = filled ? size * 0.22 : size * 0.08;
    final w    = size - pad * 2;

    final paint = Paint()
      ..color     = color
      ..style     = PaintingStyle.fill
      ..isAntiAlias = true;

    // Head circle
    final headR = w * 0.22;
    final headY = cy - w * 0.12;
    canvas.drawCircle(Offset(cx, headY), headR, paint);

    // Body — simple rounded trapezoid (shoulders)
    final bodyTop    = headY + headR + w * 0.04;
    final bodyBottom = cy + w * 0.38;
    final bodyHalfW  = w * 0.32;
    final bodyPath   = Path()
      ..moveTo(cx - bodyHalfW * 0.6, bodyTop)
      ..quadraticBezierTo(cx, bodyTop - w * 0.02, cx + bodyHalfW * 0.6, bodyTop)
      ..lineTo(cx + bodyHalfW, bodyBottom)
      ..quadraticBezierTo(cx, bodyBottom + w * 0.04, cx - bodyHalfW, bodyBottom)
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(_PersonPainter old) => old.color != color;
}