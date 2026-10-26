import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../models/mission.dart';
import '../models/user_mission.dart';
import 'info_chip.dart';

/// WIDGET PERSONALIZADO 1 — Cartão de missão.
///
/// Parâmetros:
///  * [mission]  dados da missão (título, descrição, categoria, XP...)
///  * [status]   status da missão para o usuário autenticado
///  * [onTap]    ação ao tocar no cartão (abrir os detalhes)
///  * [compact]  versão reduzida usada na Home
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    required this.status,
    this.onTap,
    this.compact = false,
  });

  final Mission mission;
  final MissionStatus status;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final category = Categories.of(mission.category);
    final completed = status == MissionStatus.completed;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: completed ? 0.75 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: completed ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryIcon(category: category, completed: completed, size: compact ? 44 : 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InfoChip(label: status.label, icon: status.icon, color: status.color),
                            if (!compact)
                              InfoChip(label: category.label, icon: category.icon, color: category.color),
                            if (!compact)
                              InfoChip(
                                label: Difficulties.label(mission.difficulty),
                                icon: Icons.star_rounded,
                                color: AppColors.lilac,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RewardBadge(xp: mission.xpReward, completed: completed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category, required this.completed, required this.size});

  final MissionCategory category;
  final bool completed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: category.color.withValues(alpha: 0.5)),
      ),
      child: Icon(
        completed ? Icons.check_rounded : category.icon,
        color: completed ? AppColors.success : category.color,
        size: size * 0.5,
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.xp, required this.completed});

  final int xp;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: completed ? null : AppColors.primaryGradient,
            color: completed ? AppColors.surfaceAlt : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+$xp',
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 2),
        const Text('XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lilac)),
      ],
    );
  }
}
