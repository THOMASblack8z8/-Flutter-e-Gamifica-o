import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/achievement_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// WIDGET PERSONALIZADO 3 — Medalha de conquista.
///
/// Parâmetros:
///  * [name], [description]  textos da conquista
///  * [iconKey]              identificador do ícone salvo no banco
///  * [unlocked]             status desbloqueada/bloqueada
///  * [criteria]             critério de desbloqueio (opcional)
///  * [unlockedAt]           data de desbloqueio (opcional)
///  * [compact]              mostra só a medalha e o nome (Home/Perfil)
///  * [size]                 tamanho da medalha
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.unlocked,
    this.criteria,
    this.unlockedAt,
    this.compact = false,
    this.size = 72,
  });

  final String name;
  final String description;
  final String iconKey;
  final bool unlocked;
  final String? criteria;
  final DateTime? unlockedAt;
  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final medal = _Medal(iconKey: iconKey, unlocked: unlocked, size: size);

    if (compact) {
      return Tooltip(
        message: '$name — $description',
        child: SizedBox(
          width: size + 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              medal,
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: unlocked ? AppColors.cardGradient : null,
        color: unlocked ? null : AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? AppColors.lilac.withValues(alpha: 0.55) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          medal,
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          if (unlocked && unlockedAt != null)
            Text(
              'Desbloqueada em ${formatDate(unlockedAt!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700),
            )
          else if (criteria != null)
            Text(
              criteria!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.iconKey, required this.unlocked, required this.size});

  final String iconKey;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(size), painter: _HexagonPainter(unlocked: unlocked)),
          Icon(
            achievementIcon(iconKey),
            size: size * 0.42,
            color: unlocked ? Colors.white : AppColors.textMuted,
          ),
          if (!unlocked)
            Positioned(
              right: size * 0.06,
              bottom: size * 0.06,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, size: size * 0.2, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  _HexagonPainter({required this.unlocked});

  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = center + Offset(math.cos(angle) * radius * 0.92, math.sin(angle) * radius * 0.92);
      i == 0 ? hex.moveTo(point.dx, point.dy) : hex.lineTo(point.dx, point.dy);
    }
    hex.close();

    if (unlocked) {
      canvas.drawPath(
        hex,
        Paint()
          ..color = AppColors.violet.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.08),
      );
    }

    canvas.drawPath(
      hex,
      Paint()
        ..shader = LinearGradient(
          colors: unlocked
              ? const [AppColors.violet, AppColors.electricBlue]
              : const [AppColors.locked, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04
        ..color = unlocked ? AppColors.gold : AppColors.textMuted.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) => oldDelegate.unlocked != unlocked;
}
