import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Ícone original do HabitQuest (escudo com estrela) e logotipo textual.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 1.12,
          child: CustomPaint(painter: _ShieldPainter()),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.18),
          Text.rich(
            TextSpan(
              children: const [
                TextSpan(text: 'Habit', style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'Quest', style: TextStyle(color: AppColors.lilac)),
              ],
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shield = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.95, h * 0.14)
      ..quadraticBezierTo(w * 0.95, h * 0.68, w * 0.5, h)
      ..quadraticBezierTo(w * 0.05, h * 0.68, w * 0.05, h * 0.14)
      ..close();

    // Brilho externo.
    canvas.drawPath(
      shield,
      Paint()
        ..color = AppColors.violet.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08),
    );

    // Corpo do escudo.
    canvas.drawPath(
      shield,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.violet, AppColors.electricBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );

    // Borda interna.
    final inner = shield.transform((Matrix4.identity()
          ..translateByDouble(w * 0.5, h * 0.5, 0, 1)
          ..scaleByDouble(0.82, 0.82, 1, 1)
          ..translateByDouble(-w * 0.5, -h * 0.5, 0, 1))
        .storage);
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Estrela central.
    final star = _starPath(Offset(w * 0.5, h * 0.46), w * 0.24, w * 0.1);
    canvas.drawPath(star, Paint()..color = Colors.white);
    canvas.drawPath(
      star,
      Paint()
        ..color = AppColors.lilac.withValues(alpha: 0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
  }

  Path _starPath(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
