import 'package:flutter/material.dart';

import '../core/constants/hero_classes.dart';
import '../core/theme/app_colors.dart';

/// Ilustração do herói desenhada com CustomPainter.
/// A cor muda conforme a classe e a aura ganha anéis conforme o nível.
/// Se o usuário tiver informado uma imagem (avatarUrl), ela é exibida
/// por cima; se a imagem falhar, o herói desenhado continua aparecendo.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    super.key,
    required this.heroClass,
    required this.level,
    this.size = 96,
    this.avatarUrl,
    this.showLevel = true,
  });

  final String heroClass;
  final int level;
  final double size;
  final String? avatarUrl;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final heroInfo = HeroClasses.of(heroClass);
    final url = avatarUrl;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeroPainter(color: heroInfo.color, level: level)),
          ),
          if (url != null && url.isNotEmpty)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(size * 0.13),
                child: ClipOval(
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          if (showLevel)
            Positioned(
              bottom: -size * 0.04,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: size * 0.02),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(size),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Text(
                    'Nv. $level',
                    style: TextStyle(
                      fontSize: (size * 0.13).clamp(10, 16),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.color, required this.level});

  final Color color;
  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);

    // Aura.
    canvas.drawCircle(
      center,
      s / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: s / 2)),
    );

    // Anéis de evolução: 1 anel a cada 2 níveis (máximo 4).
    final rings = (1 + (level - 1) ~/ 2).clamp(1, 4);
    for (var i = 0; i < rings; i++) {
      canvas.drawCircle(
        center,
        s * (0.47 - i * 0.025),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012
          ..color = AppColors.lilac.withValues(alpha: 0.75 - i * 0.15),
      );
    }

    // Disco interno.
    final innerRadius = s * 0.37;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.surfaceAlt, AppColors.backgroundDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(innerRect),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(innerRect));

    final dark = Color.lerp(color, Colors.black, 0.45)!;
    final light = Color.lerp(color, Colors.white, 0.25)!;

    // Capa.
    final cape = Path()
      ..moveTo(s * 0.30, s * 0.60)
      ..lineTo(s * 0.70, s * 0.60)
      ..lineTo(s * 0.84, s * 0.95)
      ..lineTo(s * 0.16, s * 0.95)
      ..close();
    canvas.drawPath(cape, Paint()..color = dark);

    // Ombros e armadura.
    final body = Path()
      ..moveTo(s * 0.24, s * 0.92)
      ..quadraticBezierTo(s * 0.24, s * 0.62, s * 0.50, s * 0.60)
      ..quadraticBezierTo(s * 0.76, s * 0.62, s * 0.76, s * 0.92)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(colors: [light, color], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            .createShader(innerRect),
    );

    // Emblema dourado no peito.
    final emblem = Path()
      ..moveTo(s * 0.50, s * 0.68)
      ..lineTo(s * 0.54, s * 0.73)
      ..lineTo(s * 0.50, s * 0.78)
      ..lineTo(s * 0.46, s * 0.73)
      ..close();
    canvas.drawPath(emblem, Paint()..color = AppColors.gold);

    // Elmo.
    final helmetRect = Rect.fromCenter(center: Offset(s * 0.5, s * 0.43), width: s * 0.26, height: s * 0.30);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        helmetRect,
        topLeft: Radius.circular(s * 0.13),
        topRight: Radius.circular(s * 0.13),
        bottomLeft: Radius.circular(s * 0.05),
        bottomRight: Radius.circular(s * 0.05),
      ),
      Paint()
        ..shader = LinearGradient(colors: [Colors.white, light], begin: Alignment.topLeft, end: Alignment.bottomRight)
            .createShader(helmetRect),
    );

    // Visor.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(s * 0.5, s * 0.44), width: s * 0.18, height: s * 0.045),
        Radius.circular(s * 0.02),
      ),
      Paint()..color = AppColors.backgroundDeep,
    );

    // Penacho.
    final crest = Path()
      ..moveTo(s * 0.47, s * 0.29)
      ..quadraticBezierTo(s * 0.50, s * 0.17, s * 0.62, s * 0.20)
      ..quadraticBezierTo(s * 0.54, s * 0.24, s * 0.53, s * 0.30)
      ..close();
    canvas.drawPath(crest, Paint()..color = AppColors.lilac);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.level != level;
}
