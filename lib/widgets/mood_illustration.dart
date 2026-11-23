import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/journal_entry.dart';

/// A small, consistent vector illustration for a mood across the entire app.
class MoodIllustration extends StatelessWidget {
  const MoodIllustration({super.key, required this.mood, this.size = 44});

  final MoodType mood;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _MoodPainter(mood)),
  );
}

class _MoodPainter extends CustomPainter {
  const _MoodPainter(this.mood);
  final MoodType mood;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final face = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .055
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF443A5B);

    if (mood == MoodType.productive) {
      final star = Path()
        ..moveTo(s * .24, s * .66)
        ..quadraticBezierTo(s * .62, s * .14, s * .9, s * .24)
        ..quadraticBezierTo(s * .76, s * .55, s * .24, s * .66)
        ..close();
      face.shader = const LinearGradient(
        colors: [Color(0xFFB69AEF), Color(0xFF7C58D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
      canvas.drawPath(star, face);
      final glint = Paint()..color = const Color(0xFFFFF3BF);
      canvas.drawCircle(Offset(s * .7, s * .35), s * .07, glint);
      canvas.drawLine(
        Offset(s * .1, s * .84),
        Offset(s * .38, s * .77),
        line..color = const Color(0xFF9D7CE4),
      );
      canvas.drawLine(Offset(s * .24, s * .96), Offset(s * .42, s * .83), line);
      canvas.drawCircle(Offset(s * .88, s * .08), s * .035, glint);
      canvas.drawCircle(Offset(s * .08, s * .42), s * .03, glint);
      return;
    }

    // Happy gets a sunny rim; neutral stays soft and quiet.
    if (mood == MoodType.happy) {
      final rayPaint = Paint()
        ..color = const Color(0xFFE8B94D)
        ..strokeWidth = s * .06
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final from = Offset(
          center.dx + s * .37 * math.cos(a),
          center.dy + s * .37 * math.sin(a),
        );
        final to = Offset(
          center.dx + s * .45 * math.cos(a),
          center.dy + s * .45 * math.sin(a),
        );
        canvas.drawLine(from, to, rayPaint);
      }
    }
    face.shader = LinearGradient(
      colors: mood == MoodType.happy
          ? const [Color(0xFFFFE9A8), Color(0xFFFFD66E)]
          : const [Color(0xFFE7DDFB), Color(0xFFC9B7F2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Offset.zero & size);
    canvas.drawCircle(center, s * .37, face);
    final features = Paint()..color = const Color(0xFF443A5B);
    final eyeY = center.dy - s * .045;
    canvas.drawCircle(Offset(center.dx - s * .13, eyeY), s * .028, features);
    canvas.drawCircle(Offset(center.dx + s * .13, eyeY), s * .028, features);
    final smile = Path()
      ..moveTo(center.dx - s * .13, center.dy + s * .09)
      ..quadraticBezierTo(
        center.dx,
        center.dy + (mood == MoodType.happy ? s * .25 : s * .19),
        center.dx + s * .13,
        center.dy + s * .09,
      );
    canvas.drawPath(smile, line);
    if (mood == MoodType.happy) {
      final blush = Paint()..color = const Color(0xFFFFA98F).withAlpha(130);
      canvas.drawCircle(
        Offset(center.dx - s * .22, center.dy + s * .09),
        s * .055,
        blush,
      );
      canvas.drawCircle(
        Offset(center.dx + s * .22, center.dy + s * .09),
        s * .055,
        blush,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodPainter oldDelegate) =>
      oldDelegate.mood != mood;
}
