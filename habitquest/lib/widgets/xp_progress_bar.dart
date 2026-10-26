import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// WIDGET PERSONALIZADO 2 — Barra de XP.
///
/// Parâmetros:
///  * [level]       nível atual
///  * [currentXp]   XP já obtido dentro do nível atual
///  * [requiredXp]  XP total que o nível atual exige
///  * [showLabels]  exibe textos acima/abaixo da barra
///  * [height]      altura da barra
///
/// A barra anima suavemente sempre que o XP muda.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.level,
    required this.currentXp,
    required this.requiredXp,
    this.showLabels = true,
    this.height = 12,
  });

  final int level;
  final int currentXp;
  final int requiredXp;
  final bool showLabels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fraction = requiredXp <= 0 ? 1.0 : (currentXp / requiredXp).clamp(0.0, 1.0);
    final missing = (requiredXp - currentXp).clamp(0, requiredXp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels) ...[
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                'Nível $level',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '$currentXp / $requiredXp XP',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.lilac),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          label: 'Progresso de XP',
          value: '${(fraction * 100).round()} por cento',
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDeep.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(height),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Container(
                      width: constraints.maxWidth * value,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.violet, AppColors.electricBlue, AppColors.lilac],
                        ),
                        borderRadius: BorderRadius.circular(height),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 6),
          Text(
            'Faltam $missing XP para o nível ${level + 1}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
